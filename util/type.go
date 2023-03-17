package util

const (
	ComplianceScan     = "compliance"
	ComplianceScanLogs = "compliance-scan-logs"
)

type Config struct {
	ManagementConsoleUrl      string `json:"management_console_url,omitempty"`
	ManagementConsolePort     string `json:"management_console_port,omitempty"`
	DeepfenceKey              string `json:"deepfence_key,omitempty"`
	ScanId                    string `json:"scan_id,omitempty"`
	NodeType                  string `json:"node_type,omitempty"`
	NodeName                  string `json:"node_name"`
	NodeId                    string `json:"node_id,omitempty"`
	HostName                  string `json:"host_name,omitempty"`
	ComplianceCheckType       string `json:"compliance_check_type"`
	ComplianceResultsFilePath string
	ComplianceStatusFilePath  string
}

type ComplianceDoc struct {
	Type                  string `json:"type"`
	TimeStamp             int64  `json:"time_stamp"`
	Timestamp             string `json:"@timestamp"`
	Masked                bool   `json:"masked"`
	NodeId                string `json:"node_id"`
	NodeType              string `json:"node_type"`
	KubernetesClusterName string `json:"kubernetes_cluster_name"`
	KubernetesClusterId   string `json:"kubernetes_cluster_id"`
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
	ScanId                string `json:"scan_id"`
}

type ComplianceScanLog struct {
	Type                  string         `json:"type"`
	TimeStamp             int64          `json:"time_stamp"`
	Timestamp             string         `json:"@timestamp"`
	Masked                bool           `json:"masked"`
	NodeId                string         `json:"node_id"`
	NodeType              string         `json:"node_type"`
	KubernetesClusterName string         `json:"kubernetes_cluster_name"`
	KubernetesClusterId   string         `json:"kubernetes_cluster_id"`
	NodeName              string         `json:"node_name"`
	ScanStatus            string         `json:"scan_status"`
	ScanMessage           string         `json:"scan_message"`
	ComplianceCheckType   string         `json:"compliance_check_type"`
	TotalChecks           int            `json:"total_checks"`
	Result                map[string]int `json:"result"`
	ScanId                string         `json:"scan_id"`
}
