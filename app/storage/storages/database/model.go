package database

import "github.com/google/uuid"

type Storage struct {
	Id   uuid.UUID `gorm:"primaryKey;type:uuid;"`
	Data []byte
}

func (Storage) TableName() string {
  return "Storage"
}