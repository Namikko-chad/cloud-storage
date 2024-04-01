package app

import (
	"log"
	"os"

	_ "github.com/joho/godotenv/autoload"

	"cloud-storage/app/config"
	"cloud-storage/app/database"
	"cloud-storage/app/storage"

	"cloud-storage/app/interfaces"
	"cloud-storage/app/sync"
)

var server interfaces.Server

func StartServer() interfaces.Server {
	server = interfaces.Server{
		Config: &config.Server,
		Logger: log.New(os.Stdout, "[FileSeCloudStoragervice] ", log.LstdFlags),
	}
	server.DB = database.ConnectDB(server.Logger)
	storagePackage, err := storage.New(&server)
	if err != nil {
		panic(err)
	}
	syncPackage, err := sync.New(&server)
	if err != nil {
		panic(err)
	}
	server.Packages = map[string]interfaces.IPackage{}
	server.Packages["storage"] = storagePackage
	server.Packages["sync"] = syncPackage

	for _, p := range server.Packages {
		err := p.Start()
		if err != nil {
			panic(err)
		}
	}
	server.Logger.Print("Server successfully started")
	return server
}

func StopServer() {
	server.Logger.Print("Stopping server")
	for _, p := range server.Packages {
		err := p.Stop()
		if err != nil {
			panic(err)
		}
	}
}
