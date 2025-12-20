package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"net"
	"os"

	sk "github.com/deepfence/compliance/share/system/sidekick"
	"github.com/rs/zerolog/log"
)

func verifyParentProcess() bool {
	path := fmt.Sprintf("/proc/%d/exe", os.Getppid())
	if caller, err := os.Readlink(path); err == nil {
		return caller == "/usr/local/bin/nstools"
	}
	return false
}

func main() {
	if !verifyParentProcess() {
		os.Exit(-1)
	}

	argAct := flag.String("act", "", "action")
	argIP := flag.String("ip", "", "ip")
	flag.Parse()

	switch *argAct {
	case "ports":
		ifaces := sk.GetGlobalAddrs()
		value, _ := json.Marshal(ifaces)
		log.Info().Str("ifaces", string(value)).Msg("")
	case "route":
		ip := net.ParseIP(*argIP)
		if ip == nil {
			os.Exit(-1)
		}

		_, ipnet, err := sk.GetRouteIfaceAddr(ip)
		if err != nil {
			os.Exit(-1)
		}
		log.Info().Str("ipnet", ipnet.String()).Msg("")
	default:
		os.Exit(-1)
	}
}
