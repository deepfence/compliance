package main

import (
	"encoding/json"
	"fmt"
	"os"
)

type Script struct {
	Files []string `json:"files"`
	Name string `json:"name"`
	Desc string `json:"desc"`
}

const configFile = "/usr/local/bin/compliance_check/config.json"

func LoadConfig() (map[string]Script, error) {
	configFile, err := os.Open(configFile)
	defer configFile.Close()
	if err != nil {
		fmt.Println("error in reading config json file:" + err.Error())
		return nil, err
	}
	jsonParser := json.NewDecoder(configFile)
	var config map[string]Script
	err = jsonParser.Decode(&config)
	if err != nil {
		fmt.Println("error in parsing config json:" + err.Error())
		return nil, err
	}
	return config, nil
}