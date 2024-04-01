package storage

import (
	"errors"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type FileRepository struct {
	DB *gorm.DB
}

func (r *FileRepository) Create (file *File) error {
	r.DB.Create(file)
	return r.DB.Error
}

func (r *FileRepository) Find (file *File) error {
	r.DB.Where(file).Find(file)
	return r.DB.Error
}

func (r *FileRepository) Retrieve (fileId uuid.UUID) (*File, error) {
	var file File
	if err := r.DB.Where("id = ?", fileId).First(&file).Error; err != nil {
		return nil, err
	}
	if (File{}) == file {
		return nil, errors.New("file not found")
	}
	return &file, nil
}

func (r *FileRepository) Update (file *File) error {
	r.DB.Save(file)
	return r.DB.Error
}

func (r *FileRepository) Delete (fileId uuid.UUID) error {
	return r.DB.Where("id = ?", fileId).Delete(&File{}).Error
}
