package main

import (
	"flag"

	"github.com/deepfence/compliance/scanner"
	log "github.com/sirupsen/logrus"
)

func main() {
	benchId := flag.String("bench-id", "", "The id of set of scripts to be run for compliance check")
	flag.String("NODE_TYPE", "", "Kubernetes node role master/worker")
	flag.Parse()
	config, err := scanner.LoadConfig()
	if err != nil {
		return
	}
	if *benchId == "" {
		log.Error("Bench Id is required. Exiting.")
		return
	}
	script, found := config[*benchId]
	if !found {
		log.Error("BenchId not found. Exiting. ")
		return
	}
	b := scanner.Bench{
		Script: script,
	}
	b.RunScripts()
}
