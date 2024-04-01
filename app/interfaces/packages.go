package interfaces

import (
	"cloud-storage/app/config"
	"log"

	"gorm.io/gorm"
)

type IPackage interface {
	Start() error
	Stop() error
	Info() *Package
}

type Package struct {
	IPackage
	Name    string
	Depends []string
}

type Server struct {
	Config *config.ServerConfig
	DB     *gorm.DB
	Logger *log.Logger

	Packages map[string]IPackage
}

func (p Package) Info() *Package {
	return &p
}
