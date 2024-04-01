package storage

import (
	"cloud-storage/app/interfaces"

	"gorm.io/gorm"
)

type StoragePackage struct {
	interfaces.Package
	server  *interfaces.Server
	db      *gorm.DB
	Storage *Storage
}

func New(server *interfaces.Server) (*StoragePackage, error) {
	storage, err := StartStorage(server)
	if err != nil {
		panic(err)
	}
	sp := &StoragePackage{
		db:      server.DB,
		Storage: storage,
		Package: interfaces.Package{
			Name:    "storage",
			Depends: []string{"db"},
		},
		server: server,
	}

	return sp, nil
}

func (sp *StoragePackage) Start() error {
	sp.server.Logger.Print("[Storage] Started")
	return nil
}

func (sp *StoragePackage) Stop() error {
	sp.server.Logger.Print("[Storage] Stopped")
	return nil
}
