package config

import (
	"cloud-storage/app/utils"
)

type ServerConfig struct {
	Debug bool
}

var (
	Server ServerConfig
)

func init() {
	Server = ServerConfig{
		Debug: utils.GetEnv("DEBUG", "false") == "true",
	}
}
