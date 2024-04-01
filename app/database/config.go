package database

import (
	"cloud-storage/app/utils"
)

type TDataBaseConfig struct {
	Link string
	Type string
	Log  bool
}

var (
	DataBaseConfig *TDataBaseConfig
)

func init() {
	DataBaseConfig = &TDataBaseConfig{
		Link: utils.GetEnv("DATABASE_URL", ""),
		Type: utils.GetEnv("DATABASE_TYPE", "postgres"),
		Log:  utils.GetEnv("DEBUG", "false") == "true",
	}
}
