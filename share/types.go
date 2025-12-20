package share

import (
	"time"
)

const DefaultCVEDBName = "cvedb"
const CompactCVEDBName = "cvedb.compact"
const RegularCVEDBName = "cvedb.regular"
const CVEDatabaseFolder = "/etc/neuvector/db/"

const ProfileFolder string = "/var/neuvector/profile/"
const ProfileMemoryFileFmt string = ProfileFolder + "%smemory.prof"
const ProfileGoroutineFileFmt string = ProfileFolder + "%sgoroutine.prof"
const ProfileCPUFileFmt string = ProfileFolder + "%scpu.prof"

const CustomScriptFailedPrefix string = "Failed to run the custom check"

const (
	NeuVectorLabelImage string = "neuvector.image"
	NeuVectorLabelRole  string = "neuvector.role"

	NeuVectorRoleController string = "controller"
	NeuVectorRoleEnforcer   string = "enforcer"
	NeuVectorRoleManager    string = "manager"
)

const UnusedGroupAgingDefault uint8 = 24 //aging time in Hour
const UnusedGroupAgingMax uint8 = 168    //aging time in Hour,24*7

const (
	PolicyModeLearn       string = "Discover"
	PolicyModeEvaluate    string = "Monitor"
	PolicyModeEnforce     string = "Protect"
	PolicyModeUnavailable string = "N/A"
)

const (
	ProfileDefault   string = "default" // (obsolete) it's equal to "zero-drift"
	ProfileShield    string = "shield"  // (obsolete) it's equal to "zero-drift"
	ProfileBasic     string = "basic"
	ProfileZeroDrift string = "zero-drift"
)

const (
	PolicyActionOpen     string = "open" // Policy is not enforced
	PolicyActionLearn    string = "learn"
	PolicyActionAllow    string = "allow"
	PolicyActionDeny     string = "deny"
	PolicyActionViolate  string = "violate"
	PolicyActionCheckApp string = "check_app"
)

const (
	VulnSeverityCritical string = "Critical"
	VulnSeverityHigh     string = "High"
	VulnSeverityMedium   string = "Medium"
	VulnSeverityLow      string = "Low"
)

const (
	DlpRuleActionAllow   string = "allow"
	DlpRuleActionDrop    string = "deny"
	DlpRuleStatusEnable  string = "enable"
	DlpRuleStatusDisable string = "disable"
	DlpRuleSeverityInfo  string = "info"
	DlpRuleSeverityLow   string = "low"
	DlpRuleSeverityMed   string = "medium"
	DlpRuleSeverityHigh  string = "high"
	DlpRuleSeverityCrit  string = "critical"
)

const ContainerRuntimeDocker string = "docker"
const DomainDelimiter string = "."

const (
	PlatformDocker     = "Docker"
	PlatformAmazonECS  = "Amazon-ECS"
	PlatformKubernetes = "Kubernetes"
	PlatformRancher    = "Rancher"
	PlatformAliyun     = "Aliyun"

	FlavorSwarm     = "Swarm"
	FlavorUCP       = "UCP"
	FlavorOpenShift = "OpenShift"
	FlavorRancher   = "Rancher"
	FlavorIKE       = "IKE"
	FlavorGKE       = "GKE"

	NetworkFlannel   = "Flannel"
	NetworkCalico    = "Calico"
	NetworkDefault   = "Default"
	NetworkProxyMesh = "ProxyMeshLo"
)

const (
	ENV_PLATFORM_INFO = "NV_PLATFORM_INFO"
	ENV_SYSTEM_GROUPS = "NV_SYSTEM_GROUPS"
	ENV_DISABLE_PCAP  = "DISABLE_PACKET_CAPTURE"
)

const (
	ENV_PLT_PLATFORM    = "platform"
	ENV_PLT_INTF_PREFIX = "if-"
	ENV_PLT_INTF_HOST   = "host"
	ENV_PLT_INTF_GLOBAL = "global"
)

// Registry
const DefaultOpenShiftRegistryURL = "docker-registry.default.svc"

const (
	RegistryTypeAWSECR           = "Amazon ECR Registry"
	RegistryTypeAzureACR         = "Azure Container Registry"
	RegistryTypeDocker           = "Docker Registry"
	RegistryTypeGCR              = "Google Container Registry"
	RegistryTypeJFrog            = "JFrog Artifactory"
	RegistryTypeOpenShift        = "OpenShift Registry"
	RegistryTypeRedhat_Deprecate = "Red Hat/OpenShift Registry"
	RegistryTypeRedhat           = "Red Hat Public Registry"
	RegistryTypeSonatypeNexus    = "Sonatype Nexus"
	RegistryTypeGitlab           = "Gitlab"
	RegistryTypeIBMCloud         = "IBM Cloud Container Registry"
)

const (
	JFrogModeRepositoryPath = "Repository Path"
	JFrogModeSubdomain      = "Subdomain"
	JFrogModePort           = "Port"
)

// Response rule
const (
	EventRuntime          string = "security-event" // EventThreat + EventIncident + EventViolation + EventDlp +EventWaf
	EventEvent            string = "event"
	EventActivity         string = "activity"
	EventCVEReport        string = "cve-report"
	EventThreat           string = "threat"
	EventIncident         string = "incident"
	EventViolation        string = "violation"
	EventBenchmark_UNUSED string = "benchmark"
	EventCompliance       string = "compliance"
	EventAdmCtrl          string = "admission-control"
	EventDlp              string = "dlp"
	EventServerless       string = "serverless"
	EventWaf              string = "waf"
)

const (
	RuleAttribGroup    string = "group"
	RuleAttribCriteria string = "criteria"
	RuleAttribAction   string = "action"
	RuleAttribLogLevel string = "log-level"
)

const (
	EventCondTypeName        string = "name"
	EventCondTypeCVEName     string = "cve-name"
	EventCondTypeCVEHigh     string = "cve-high"
	EventCondTypeCVEMedium   string = "cve-medium"
	EventCondTypeLevel       string = "level"
	EventCondTypeProc        string = "process"
	EventCondTypeBenchNumber string = "number"
)

const (
	EventActionQuarantine  string = "quarantine"
	EventActionSuppressLog string = "suppress-log"
	EventActionWebhook     string = "webhook"
)

const (
	FileAccessBehaviorBlock   = "block_access"
	FileAccessBehaviorMonitor = "monitor_change"
)

type ProbeContainerStart struct {
	Id          string
	RootPid_alt int
}

const GroupNVProtect string = "NV.Protect"
const AwsNvSecKey string = "nvsecKey"
const (
	// show only
	CloudResDataLost = "data_lost"
	// transient state
	CloudResScheduled  = "scheduled"
	CloudResScanning   = "scanning"
	CloudResSuspending = "suspending"
	// final state
	CloudResSuspend = "suspend"
	CloudResReady   = "ready"
	CloudResError   = "error"
)

// AWS Regions - migrated from aws-sdk-go v1 to direct string constants
// These are standard AWS region identifiers compatible with AWS SDK v2
// Updated: December 2024 - Includes all currently available regions
var AwsRegionAll = []string{
	// US Regions
	"us-east-1", // N. Virginia
	"us-east-2", // Ohio
	"us-west-1", // N. California
	"us-west-2", // Oregon

	// Canada
	"ca-central-1", // Central
	"ca-west-1",    // Calgary

	// Mexico
	"mx-central-1", // Central

	// South America
	"sa-east-1", // São Paulo

	// Europe
	"eu-central-1", // Frankfurt
	"eu-central-2", // Zurich
	"eu-north-1",   // Stockholm
	"eu-south-1",   // Milan
	"eu-south-2",   // Spain
	"eu-west-1",    // Ireland
	"eu-west-2",    // London
	"eu-west-3",    // Paris

	// Middle East
	"me-central-1", // UAE
	"me-south-1",   // Bahrain
	"il-central-1", // Tel Aviv

	// Africa
	"af-south-1", // Cape Town

	// Asia Pacific
	"ap-east-1",      // Hong Kong
	"ap-east-2",      // Taipei
	"ap-northeast-1", // Tokyo
	"ap-northeast-2", // Seoul
	"ap-northeast-3", // Osaka
	"ap-south-1",     // Mumbai
	"ap-south-2",     // Hyderabad
	"ap-southeast-1", // Singapore
	"ap-southeast-2", // Sydney
	"ap-southeast-3", // Jakarta
	"ap-southeast-4", // Melbourne
	"ap-southeast-5", // Malaysia
	"ap-southeast-6", // New Zealand
	"ap-southeast-7", // Thailand

	// AWS China (separate partition)
	// "cn-north-1",     // Beijing - Requires separate credentials
	// "cn-northwest-1", // Ningxia - Requires separate credentials

	// AWS GovCloud (US) (separate partition)
	// "us-gov-east-1", // GovCloud US-East - Requires separate credentials
	// "us-gov-west-1", // GovCloud US-West - Requires separate credentials
}

const (
	CloudAws   = "aws_cloud"
	CloudAzure = "azure_cloud"
)

const (
	AwsLambdaFunc  = "aws_lambda_func"
	AwsLambdaLayer = "aws_lambda_layer"
	AwsLambdaApp   = "aws_lambda_app"
	AwsLambdaRt    = "aws_lambda_runtime"
)

const NV_VBR_PORT_MTU int = 2048       //2k
const NV_VBR_PORT_MTU_JUMBO int = 9216 //9k

// Stats
const ContainerStatsSlots uint = 60 // 5s * 60 = 3m

type ContainerStats struct {
	PrevCPU       uint64
	PrevCPUSystem uint64
	ReadAt        time.Time
	CurSlot       uint
	Cpu           [ContainerStatsSlots]float64
	Memory        [ContainerStatsSlots]uint64
}
