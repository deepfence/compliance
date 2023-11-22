package scanner

import (
	"encoding/json"
	"os"

	log "github.com/sirupsen/logrus"
)

type Script struct {
	Files []string `json:"files"`
	Name  string   `json:"name"`
	Desc  string   `json:"desc"`
	Vars  []string `json:"variables"`
}

func getDfInstallDir() string {
	installDir, exists := os.LookupEnv("DF_INSTALL_DIR")
	if exists {
		return installDir
	} else {
		return ""
	}
}

var configFile = getDfInstallDir() + "/usr/local/bin/compliance_check/config.json"

func LoadConfig() (map[string]Script, error) {
	configFile, err := os.Open(configFile)
	defer func() { _ = configFile.Close() }()
	if err != nil {
		log.Error("error in reading config json file:" + err.Error())
		return nil, err
	}
	jsonParser := json.NewDecoder(configFile)
	var config map[string]Script
	err = jsonParser.Decode(&config)
	if err != nil {
		log.Error("error in parsing config json:" + err.Error())
		return nil, err
	}
	return config, nil
}
