package storage

import (
	"cloud-storage/app/database"
)

type File struct {
	database.AbstractModel
	EXT     string `gorm:"type:varchar(10);column:ext;not null"`
	MIME    string `gorm:"type:varchar(255);column:mime;not null"`
	Size    uint64 `gorm:"type:bigint;not null"`
	Storage string `gorm:"type:varchar(255);not null"`
	Hash    string `gorm:"type:varchar(255);not null"`
}
