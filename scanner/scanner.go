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
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

type ComplianceScanner struct {
	config util.Config
}

var (
	scanMap sync.Map

	serverlessAgent bool

	ErrScanNotFound        = errors.New("failed to stop scan, may have already completed")
	ErrScanCancelTypecast  = errors.New("failed to stop scan, cancel function is not an instance of context.CancelFunc")
	ErrComplianceCheckType = errors.New("compliance check type not found")
)

func init() {
	// Configure zerolog
	zerolog.TimeFieldFormat = "2006-01-02 15:04:05"
	log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr, TimeFormat: "2006-01-02 15:04:05"})

	lvl, ok := os.LookupEnv("LOG_LEVEL")
	// LOG_LEVEL not set, let's default to info
	if !ok {
		lvl = "info"
	}
	// parse string and set log level
	switch strings.ToLower(lvl) {
	case "debug":
		zerolog.SetGlobalLevel(zerolog.DebugLevel)
	case "info":
		zerolog.SetGlobalLevel(zerolog.InfoLevel)
	case "warn", "warning":
		zerolog.SetGlobalLevel(zerolog.WarnLevel)
	case "error":
		zerolog.SetGlobalLevel(zerolog.ErrorLevel)
	default:
		zerolog.SetGlobalLevel(zerolog.InfoLevel)
	}

	scanMap = sync.Map{}

	if os.Getenv("DF_SERVERLESS") == "true" {
		serverlessAgent = true
	} else {
		serverlessAgent = false
	}
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
	if serverlessAgent == true {
		return c.PublishScanStatus("", "COMPLETE", nil)
	}

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
	log.Info().Str("scanid", c.config.ScanID).Msg("Adding to scanMap")
	scanMap.Store(c.config.ScanID, cancel)
	defer func() {
		log.Info().Str("scanid", c.config.ScanID).Msg("Removing from scanMap")
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
		log.Info().Str("scanid", c.config.ScanID).Msg("Scan stopped by user request")
		return c.PublishScanStatus("Scan stopped by user request", "CANCELLED", nil)
	}

	return c.PublishScanStatus("", "COMPLETE", nil)
}

func (c *ComplianceScanner) PublishScanStatus(scanMsg string, status string, extras map[string]interface{}) error {
	scanMsg = strings.ReplaceAll(scanMsg, "\n", " ")
	scanLog := map[string]interface{}{
		"scan_id":      c.config.ScanID,
		"scan_message": scanMsg,
		"scan_status":  status,
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
		log.Error().Err(err).Msg("error opening file")
		return fmt.Errorf("os.Openfile %s: %w", c.config.ComplianceStatusFilePath, err)
	}
	byteJSON, err := json.Marshal(scanLog)
	if err != nil {
		log.Error().Interface("scanLog", scanLog).Msg("Error in formatting json")
		return fmt.Errorf("json.Marshal: %w", err)
	}
	if _, err = f.WriteString(string(byteJSON) + "\n"); err != nil {
		log.Error().Err(err).Msg("")
		return fmt.Errorf("f.WriteString: %w", err)
	}
	return nil
}

func (c *ComplianceScanner) IngestComplianceResults(complianceDocs []util.ComplianceDoc) error {
	log.Debug().Int("count", len(complianceDocs)).Msg("Number of docs to ingest")
	data := make([]map[string]interface{}, len(complianceDocs))
	for index, complianceDoc := range complianceDocs {
		mapData, err := util.StructToMap(complianceDoc)
		if err == nil {
			data[index] = mapData
		} else {
			log.Error().Err(err).Msg("")
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
			log.Error().Err(err).Msg("")
			continue
		}
		strJSON := string(byteJSON)
		strJSON = strings.ReplaceAll(strJSON, "\n", " ")
		if _, err = f.WriteString(strJSON + "\n"); err != nil {
			log.Error().Err(err).Msg("")
		}
	}
	return nil
}
