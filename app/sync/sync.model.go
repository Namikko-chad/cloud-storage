package sync

import (
	"cloud-storage/app/database"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type CloudFile struct {
	database.AbstractModel
	FileId     uuid.UUID `gorm:"type:uuid;"`
	Path       string    `gorm:"type:varchar(255);not null"`
	Name       string    `gorm:"type:varchar(255);not null"`
	Hash       string    `gorm:"type:varchar(255);not null"`
	ModifiedAt time.Time
	DeletedAt  gorm.DeletedAt `gorm:"index"`
}
