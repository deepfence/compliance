package util

const (
	ComplianceScan     = "compliance"
	ComplianceScanLogs = "compliance-scan-logs"
)

type Config struct {
	ManagementConsoleURL      string   `json:"management_console_url,omitempty"`
	ManagementConsolePort     string   `json:"management_console_port,omitempty"`
	DeepfenceKey              string   `json:"deepfence_key,omitempty"`
	ScanID                    string   `json:"scan_id,omitempty"`
	NodeType                  string   `json:"node_type,omitempty"`
	NodeName                  string   `json:"node_name"`
	NodeID                    string   `json:"node_id,omitempty"`
	HostName                  string   `json:"host_name,omitempty"`
	ComplianceCheckTypes      []string `json:"compliance_check_types"`
	ComplianceResultsFilePath string
	ComplianceStatusFilePath  string
}

type ComplianceDoc struct {
	Type                  string `json:"type"`
	TimeStamp             int64  `json:"time_stamp"`
	Timestamp             string `json:"@timestamp"`
	Masked                bool   `json:"masked"`
	NodeID                string `json:"node_id"`
	NodeType              string `json:"node_type"`
	KubernetesClusterName string `json:"kubernetes_cluster_name"`
	KubernetesClusterID   string `json:"kubernetes_cluster_id"`
	NodeName              string `json:"node_name"`
	TestCategory          string `json:"test_category"`
	TestNumber            string `json:"test_number"`
	TestInfo              string `json:"description"`
	RemediationScript     string `json:"remediation_script,omitempty"`
	RemediationAnsible    string `json:"remediation_ansible,omitempty"`
	RemediationPuppet     string `json:"remediation_puppet,omitempty"`
	TestRationale         string `json:"test_rationale"`
	TestSeverity          string `json:"test_severity"`
	TestDesc              string `json:"test_desc"`
	Status                string `json:"status"`
	ComplianceCheckType   string `json:"compliance_check_type"`
	ScanID                string `json:"scan_id"`
}
