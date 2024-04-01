package sync

import (
	"cloud-storage/app/interfaces"
	"cloud-storage/app/storage"
	"context"

	"gorm.io/gorm"
)

type SyncPackage struct {
	interfaces.Package
	config     *SyncConfig
	server     *interfaces.Server
	storage    *storage.Storage
	repository *CloudFileRepository
	db         *gorm.DB

	ctx            context.Context
	cancel         context.CancelFunc
	uploadStream   chan CloudFile
	downloadStream chan CloudFile
}

func New(server *interfaces.Server) (*SyncPackage, error) {
	sp := &SyncPackage{
		db:     server.DB,
		config: loadConfig(),
		repository: &CloudFileRepository{
			DB: server.DB,
		},
		Package: interfaces.Package{
			Name:    "sync",
			Depends: []string{"storage"},
		},
		server:         server,
		uploadStream:   make(chan CloudFile),
		downloadStream: make(chan CloudFile),
	}
	return sp, nil
}

func (sp *SyncPackage) Start() error {
	sp.storage = sp.server.Packages["storage"].(*storage.StoragePackage).Storage
	go sp.downloads()
	go sp.uploads()
	ctx, cancel := context.WithCancel(context.Background())
	sp.ctx = ctx
	sp.cancel = cancel
	sp.server.Logger.Print("[Sync] Started")
	sp.Sync()
	return nil
}

func (sp *SyncPackage) Stop() error {
	sp.cancel()
	close(sp.uploadStream)
	close(sp.downloadStream)
	saveConfig(sp.config)
	sp.server.Logger.Print("[Sync] Stopped")
	return nil
}
