package database

import (
	storages "cloud-storage/app/storage/storages"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Database struct {
	storages.Config
	db *gorm.DB
}

func New(db *gorm.DB) (*Database, error) {
	return &Database{
		storages.Config{
			Capacity:      1024 * 1024 * 1024,
			Enabled:       true,
			FileSizeLimit: 8 * 1024 * 1024,
		},
		db,
	}, nil
}

func (s *Database) GetConfig() *storages.Config {
	return &s.Config
}

func (s *Database) GetName() string {
	return "db"
}

func (s *Database) SaveFile(fileId uuid.UUID, data []byte) error {
	file := Storage{
		Id:   fileId,
		Data: data,
	}
	return s.db.Create(&file).Error
}

func (s *Database) LoadFile(fileId uuid.UUID) ([]byte, error) {
	var file = Storage{}
	err := s.db.Model(&Storage{}).Where("id = ?", fileId).First(&file).Error
	if err != nil {
		return nil, err
	}
	return file.Data, nil
}

func (s *Database) DeleteFile(fileId uuid.UUID) error {
	return s.db.Where("id = ?", fileId).Delete(&Storage{}).Error
}
