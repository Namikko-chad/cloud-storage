package app

import (
	db "cloud-storage/app/database"
	modelsStorage "cloud-storage/app/storage"
	modelsStorageDatabase "cloud-storage/app/storage/storages/database"
	modelsSync "cloud-storage/app/sync"
	"os"

	"log"
)

func Sync() {
	logger := log.New(os.Stdout, "[CloudStorage] ", log.LstdFlags)
	logger.Print("[Database] Synchronization started")
	db := db.ConnectDB(logger)
	db.Exec(`CREATE EXTENSION IF NOT EXISTS "uuid-ossp"`)
	err := db.AutoMigrate(&modelsStorage.File{}, &modelsStorageDatabase.Storage{}, &modelsSync.CloudFile{})
	if err == nil {
		logger.Print("[Database] Synchronization completed")
	} else {
		logger.Panic("[Database] Synchronization error", err)
		panic("Synchronization error")
	}
}
