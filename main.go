package main

import (
	"flag"
	"fmt"
)

func main() {
	benchId := flag.String("bench-id", "", "The id of set of scripts to be run for compliance check")
	flag.String("NODE_TYPE", "", "Kubernetes node role master/worker")
	flag.Parse()
	config, err := LoadConfig()
	if err != nil {
		return
	}
	if *benchId == "" {
		fmt.Println("Bench Id is required. Exiting.")
	}
	script, found := config[*benchId]
	if !found {
		fmt.Println("BenchId not found. Exiting. ")
	}
	b := Bench{
		script: script,
	}
	b.RunScripts()
}
