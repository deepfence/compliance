module github.com/deepfence/compliance

go 1.17

replace github.com/kubernetes/cri-api => k8s.io/cri-api v0.22.3

require (
	github.com/aws/aws-sdk-go v1.42.22
	github.com/sirupsen/logrus v1.8.1
	github.com/vishvananda/netlink v1.1.0
	github.com/vishvananda/netns v0.0.0-20211101163701-50045581ed74
// github.com/zcalusic/sysinfo latest
)

require golang.org/x/sys v0.0.0-20210423082822-04245dca01da // indirect
