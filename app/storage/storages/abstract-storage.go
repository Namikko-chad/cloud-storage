package storages

import "github.com/google/uuid"

type Config struct {
	Enabled bool
  FileSizeLimit uint64
  Capacity uint64
}

type IStorage interface {
	SaveFile(fileId uuid.UUID, data []byte) error
	LoadFile(fileId uuid.UUID) ([]byte, error)
	DeleteFile(fileId uuid.UUID) error
	GetConfig() *Config
	GetName() string
}
