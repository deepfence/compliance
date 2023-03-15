package util

import (
	"encoding/json"
	"time"
)

func GetIntTimestamp() int64 {
	return time.Now().UTC().UnixNano() / 1000000
}

func GetDatetimeNow() string {
	return time.Now().UTC().Format("2006-01-02T15:04:05.000") + "Z"
}

// StructToMap Converts a struct to a map while maintaining the json alias as keys
func StructToMap(obj interface{}) (newMap map[string]interface{}, err error) {
	data, err := json.Marshal(obj) // Convert to a json string

	if err != nil {
		return
	}

	err = json.Unmarshal(data, &newMap) // Convert to a map
	return
}
