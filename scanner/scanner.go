package scanner

import (
	"context"
	"crypto/md5"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"github.com/deepfence/compliance/util"
	"github.com/sirupsen/logrus"
)

type ComplianceScanner struct {
	config util.Config
}

var (
	scanMap sync.Map

	ErrScanNotFound        = errors.New("failed to stop scan, may have already completed")
	ErrScanCancelTypecast  = errors.New("failed to stop scan, cancel function is not an instance of context.CancelFunc")
	ErrComplianceCheckType = errors.New("compliance check type not found")
)

func init() {
	lvl, ok := os.LookupEnv("LOG_LEVEL")
	// LOG_LEVEL not set, let's default to debug
	if !ok {
		lvl = "info"
	}
	// parse string, this is built-in feature of logrus
	ll, err := logrus.ParseLevel(lvl)
	if err != nil {
		ll = logrus.InfoLevel
	}
	// set global log level
	logrus.SetLevel(ll)

	customFormatter := new(logrus.TextFormatter)
	customFormatter.TimestampFormat = "2006-01-02 15:04:05"
	logrus.SetFormatter(customFormatter)

	scanMap = sync.Map{}
}

func NewComplianceScanner(config util.Config) (*ComplianceScanner, error) {
	scriptConfig, err := LoadConfig()
	if err != nil {
		return nil, err
	}
	for _, complianceCheckType := range config.ComplianceCheckTypes {
		_, exists := scriptConfig[complianceCheckType]
		if !exists {
			return nil, fmt.Errorf("invalid scan_type %s", complianceCheckType)
		}
	}
	if config.ScanID == "" {
		return nil, errors.New("scan_id is empty")
	}
	return &ComplianceScanner{config: config}, nil
}

func StopScan(scanID string) error {
	cancelFnObj, found := scanMap.Load(scanID)
	if !found {
		return ErrScanNotFound
	}

	cancelFn, ok := cancelFnObj.(context.CancelFunc)
	if !ok {
		return ErrScanCancelTypecast
	}

	cancelFn()

	return nil
}

func (c *ComplianceScanner) RunComplianceScan() error {
	err := c.PublishScanStatus("", "IN_PROGRESS", nil)
	if err != nil {
		return err
	}
	tempFileName := fmt.Sprintf("/tmp/tmp-%s.json", c.config.ScanID)
	defer os.Remove(tempFileName)
	scriptConfig, err := LoadConfig()
	if err != nil {
		return err
	}
	var complianceScanResults []util.ComplianceDoc

	ctx, cancel := context.WithCancel(context.Background())
	logrus.Infof("Adding to scanMap, scanid:%s", c.config.ScanID)
	scanMap.Store(c.config.ScanID, cancel)
	defer func() {
		logrus.Infof("Removing from scanMap, scanid:%s", c.config.ScanID)
		scanMap.Delete(c.config.ScanID)
	}()

	stopped := false
	for _, complianceCheckType := range c.config.ComplianceCheckTypes {
		script, found := scriptConfig[complianceCheckType]
		if !found {
			return ErrComplianceCheckType
		}
		b := Bench{
			Script: script,
		}
		benchItems, err := b.RunScripts(ctx)
		if err != nil && ctx.Err() == context.Canceled {
			stopped = true
			break
		}

		timestamp := util.GetIntTimestamp()
		timestampStr := util.GetDatetimeNow()
		for _, item := range benchItems {
			compScan := util.ComplianceDoc{
				Type:                util.ComplianceScanLogs,
				TimeStamp:           timestamp,
				Timestamp:           timestampStr,
				Masked:              false,
				TestCategory:        item.TestCategory,
				TestNumber:          complianceCheckType + "_" + item.TestNum,
				TestInfo:            item.Header,
				TestRationale:       "",
				TestSeverity:        "",
				TestDesc:            item.TestNum + " - " + item.Level,
				Status:              strings.ToLower(item.Level),
				RemediationScript:   item.Remediation,
				RemediationPuppet:   item.RemediationImpact,
				NodeID:              fmt.Sprintf("%x", md5.Sum([]byte(item.TestNum+item.TestCategory+complianceCheckType))),
				NodeType:            "host",
				NodeName:            c.config.NodeName,
				ComplianceCheckType: complianceCheckType,
				ScanID:              c.config.ScanID,
			}
			complianceScanResults = append(complianceScanResults, compScan)
		}
		err = c.IngestComplianceResults(complianceScanResults)
		if err != nil {
			return err
		}
	}

	if stopped {
		logrus.Infof("Scan stopped by user request, scanid:%s", c.config.ScanID)
		return c.PublishScanStatus("Scan stopped by user request", "CANCELLED", nil)
	}

	return c.PublishScanStatus("", "COMPLETE", nil)
}

func (c *ComplianceScanner) PublishScanStatus(scanMsg string, status string, extras map[string]interface{}) error {
	scanMsg = strings.ReplaceAll(scanMsg, "\n", " ")
	scanLog := map[string]interface{}{
		"scan_id":                c.config.ScanID,
		"time_stamp":             util.GetIntTimestamp(),
		"@timestamp":             util.GetDatetimeNow(),
		"scan_message":           scanMsg,
		"scan_status":            status,
		"type":                   util.ComplianceScanLogs,
		"node_name":              c.config.NodeName,
		"node_id":                c.config.NodeID,
		"node_type":              "host",
		"host_name":              c.config.NodeName,
		"compliance_check_types": c.config.ComplianceCheckTypes,
		"masked":                 false,
	}
	for k, v := range extras {
		scanLog[k] = v
	}

	dir := filepath.Dir(c.config.ComplianceStatusFilePath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("os.MkdirAll %s: %w", dir, err)
	}
	f, err := os.OpenFile(c.config.ComplianceStatusFilePath, os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0600)
	if err != nil {
		logrus.Errorf("error opening file:%v", err)
		return fmt.Errorf("os.Openfile %s: %w", c.config.ComplianceStatusFilePath, err)
	}
	byteJSON, err := json.Marshal(scanLog)
	if err != nil {
		logrus.Errorf("Error in formatting json: %+v", scanLog)
		return fmt.Errorf("json.Marshal: %w", err)
	}
	if _, err = f.WriteString(string(byteJSON) + "\n"); err != nil {
		logrus.Errorf("%+v \n", err)
		return fmt.Errorf("f.WriteString: %w", err)
	}
	return nil
}

func (c *ComplianceScanner) IngestComplianceResults(complianceDocs []util.ComplianceDoc) error {
	logrus.Debugf("Number of docs to ingest: %d", len(complianceDocs))
	data := make([]map[string]interface{}, len(complianceDocs))
	for index, complianceDoc := range complianceDocs {
		mapData, err := util.StructToMap(complianceDoc)
		if err == nil {
			data[index] = mapData
		} else {
			logrus.Error(err)
		}
	}
	err := os.MkdirAll(filepath.Dir(c.config.ComplianceResultsFilePath), 0755)
	if err != nil {
		return err
	}
	f, err := os.OpenFile(c.config.ComplianceResultsFilePath, os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0600)
	if err != nil {
		return err
	}
	defer f.Close()
	for _, d := range data {
		byteJSON, err := json.Marshal(d)
		if err != nil {
			logrus.Errorf("%+v \n", err)
			continue
		}
		strJSON := string(byteJSON)
		strJSON = strings.ReplaceAll(strJSON, "\n", " ")
		if _, err = f.WriteString(strJSON + "\n"); err != nil {
			logrus.Errorf("%+v \n", err)
		}
	}
	return nil
}
