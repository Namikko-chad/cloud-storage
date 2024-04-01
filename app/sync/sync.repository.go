package sync

import (
	"time"

	"gorm.io/gorm"
)

type CloudFileRepository struct {
	DB *gorm.DB
}

func (r *CloudFileRepository) Create(cloudFile *CloudFile) error {
	return r.DB.Create(cloudFile).Error
}

func (r *CloudFileRepository) Find(cloudFile *CloudFile) error {
	request := r.DB.Where(`path = ? AND name = ?`, cloudFile.Path, cloudFile.Name)
	return request.Find(cloudFile).Error
}

func (r *CloudFileRepository) FindCreated(cloudFile *[]CloudFile, modifiedAt time.Time) error {
	request := r.DB.Where(`"createdAt" > ?`, modifiedAt)
	return request.Find(cloudFile).Error
}

func (r *CloudFileRepository) Delete(sync *CloudFile) error {
	return r.DB.Delete(sync).Error
}

func (r *CloudFileRepository) GetServerTime(sync *time.Time) error {
	return r.DB.Raw("SELECT NOW()").Scan(sync).Error
}
