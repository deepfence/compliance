package main

import (
	"context"
	"flag"
	"os"

	"github.com/deepfence/compliance/scanner"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

func main() {
	// Configure zerolog
	zerolog.TimeFieldFormat = zerolog.TimeFormatUnix
	log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr})

	benchID := flag.String("bench-id", "", "The id of set of scripts to be run for compliance check")
	flag.String("NODE_TYPE", "", "Kubernetes node role master/worker")
	flag.Parse()
	config, err := scanner.LoadConfig()
	if err != nil {
		return
	}
	if *benchID == "" {
		log.Error().Msg("bench-id is required. Exiting.")
		return
	}
	script, found := config[*benchID]
	if !found {
		log.Error().Msg("bench-id not found. Exiting. ")
		return
	}
	b := scanner.Bench{Script: script}

	if _, err := b.RunScripts(context.Background()); err != nil {
		log.Error().Err(err).Msg("RunScripts")
	}
}
