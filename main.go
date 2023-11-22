package main

import (
	"context"
	"flag"

	"github.com/deepfence/compliance/scanner"
	log "github.com/sirupsen/logrus"
)

func main() {
	benchID := flag.String("bench-id", "", "The id of set of scripts to be run for compliance check")
	flag.String("NODE_TYPE", "", "Kubernetes node role master/worker")
	flag.Parse()
	config, err := scanner.LoadConfig()
	if err != nil {
		return
	}
	if *benchID == "" {
		log.Error("bench-id is required. Exiting.")
		return
	}
	script, found := config[*benchID]
	if !found {
		log.Error("bench-id not found. Exiting. ")
		return
	}
	b := scanner.Bench{Script: script}

	if _, err := b.RunScripts(context.Background()); err != nil {
		log.Errorf("RunScripts: %v", err)
	}
}
