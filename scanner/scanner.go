package scanner

import (
	"crypto/md5"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/deepfence/compliance/util"
	"github.com/sirupsen/logrus"
)

type ComplianceScanner struct {
	config util.Config
}

func NewComplianceScanner(config util.Config) (*ComplianceScanner, error) {
	scriptConfig, err := LoadConfig()
	if err != nil {
		return nil, err
	}
	for _, complianceCheckType := range config.ComplianceCheckTypes {
		_, exists := scriptConfig[complianceCheckType]
		if !exists {
			return nil, errors.New(fmt.Sprintf("invalid scan_type %s", complianceCheckType))
		}
	}
	if config.ScanId == "" {
		return nil, errors.New("scan_id is empty")
	}
	return &ComplianceScanner{config: config}, nil
}

func (c *ComplianceScanner) RunComplianceScan() error {
	err := c.PublishScanStatus("", "IN_PROGRESS", nil)
	if err != nil {
		return err
	}
	tempFileName := fmt.Sprintf("/tmp/tmp-%s.json", c.config.ScanId)
	defer os.Remove(tempFileName)
	scriptConfig, err := LoadConfig()
	if err != nil {
		return err
	}
	var complianceScanResults []util.ComplianceDoc
	for _, complianceCheckType := range c.config.ComplianceCheckTypes {
		script, found := scriptConfig[complianceCheckType]
		if !found {
			return errors.New("Compliance Check Type not found. Exiting. ")
		}
		b := Bench{
			Script: script,
		}
		benchItems, err := b.RunScripts(false)
		timestamp := util.GetIntTimestamp()
		timestampStr := util.GetDatetimeNow()
		for _, item := range benchItems {
			compScan := util.ComplianceDoc{
				Type:                util.ComplianceScanLogs,
				TimeStamp:           timestamp,
				Timestamp:           timestampStr,
				Masked:              false,
				TestCategory:        item.TestCategory,
				TestNumber:          item.TestNum,
				TestInfo:            item.Header,
				TestRationale:       "",
				TestSeverity:        "",
				TestDesc:            item.TestNum + " - " + item.Level,
				Status:              strings.ToLower(item.Level),
				RemediationScript:   item.Remediation,
				RemediationPuppet:   item.RemediationImpact,
				NodeId:              fmt.Sprintf("%x", md5.Sum([]byte(c.config.NodeId+c.config.ScanId+item.TestNum+item.TestCategory))),
				NodeType:            "host",
				NodeName:            c.config.NodeName,
				ComplianceCheckType: complianceCheckType,
				ScanId:              c.config.ScanId,
			}
			complianceScanResults = append(complianceScanResults, compScan)
		}
		err = c.IngestComplianceResults(complianceScanResults)
		if err != nil {
			return err
		}
	}
	err = c.PublishScanStatus("", "COMPLETE", nil)
	return err
}

func (c *ComplianceScanner) publishErrorStatus(scanMsg string) {
	err := c.PublishScanStatus(scanMsg, "ERROR", nil)
	if err != nil {
		logrus.Error(err)
	}
}

func (c *ComplianceScanner) PublishScanStatus(scanMsg string, status string, extras map[string]interface{}) error {
	scanMsg = strings.Replace(scanMsg, "\n", " ", -1)
	scanLog := map[string]interface{}{
		"scan_id":                c.config.ScanId,
		"time_stamp":             util.GetIntTimestamp(),
		"@timestamp":             util.GetDatetimeNow(),
		"scan_message":           scanMsg,
		"scan_status":            status,
		"type":                   util.ComplianceScanLogs,
		"node_name":              c.config.NodeName,
		"node_id":                c.config.NodeId,
		"node_type":              "host",
		"host_name":              c.config.NodeName,
		"compliance_check_types": c.config.ComplianceCheckTypes,
		"masked":                 false,
	}
	for k, v := range extras {
		scanLog[k] = v
	}
	err := os.MkdirAll(filepath.Dir(c.config.ComplianceStatusFilePath), 0755)
	f, err := os.OpenFile(c.config.ComplianceStatusFilePath, os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0600)
	if err != nil {
		logrus.Errorf("error opening file:%v", err)
		return err
	}
	byteJson, err := json.Marshal(scanLog)
	if err != nil {
		logrus.Errorf("Error in formatting json: %+v", scanLog)
		return err
	}
	if _, err = f.WriteString(string(byteJson) + "\n"); err != nil {
		logrus.Errorf("%+v \n", err)
	}
	return err
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
		byteJson, err := json.Marshal(d)
		if err != nil {
			logrus.Errorf("%+v \n", err)
			continue
		}
		strJson := string(byteJson)
		strJson = strings.Replace(strJson, "\n", " ", -1)
		if _, err = f.WriteString(strJson + "\n"); err != nil {
			logrus.Errorf("%+v \n", err)
		}
	}
	return nil
}
