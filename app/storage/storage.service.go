package storage

import (
	"cloud-storage/app/interfaces"
	storages "cloud-storage/app/storage/storages"
	dbStorage "cloud-storage/app/storage/storages/database"
	"crypto/md5"
	"encoding/hex"
	"errors"
	"log"
	"mime"
	"net/http"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Storage struct {
	storages   map[string]storages.IStorage
	db         *gorm.DB
	repository FileRepository
	logger     *log.Logger
}

var (
	ErrFileNotFound = errors.New("file not found")
)

func StartStorage(server *interfaces.Server) (*Storage, error) {
	repository := FileRepository{
		DB: server.DB,
	}
	dbStorage, err := dbStorage.New(server.DB)
	if err != nil {
		return nil, err
	}
	storages := make(map[string]storages.IStorage)
	storages[dbStorage.GetName()] = dbStorage
	return &Storage{
		storages:   storages,
		db:         server.DB,
		repository: repository,
		logger:     server.Logger,
	}, nil
}

func (s *Storage) getStorage(size uint64) (storages.IStorage, error) {
	for _, storage := range s.storages {
		if storage.GetConfig().Capacity >= size && storage.GetConfig().Enabled {
			return storage, nil
		}
	}
	return nil, errors.New("storage not found")
}

func (s *Storage) getStorageType(storage storages.IStorage) string {
	return storage.GetName()
}

func (s *Storage) getHash(data []byte) string {
	var hash = md5.Sum(data)
	return hex.EncodeToString(hash[:])
}

func (s *Storage) getEXT(mimetype string) string {
	// TODO add validation from mime type
	// return filepath.Ext(filename)[1:]
	ext, err := mime.ExtensionsByType(mimetype)
	if (err != nil) || (len(ext) == 0) {
		return ""
	}
	return ext[0]
}

func (s *Storage) getMime(data []byte) string {
	return http.DetectContentType(data)
}

func (s *Storage) getSize(data []byte) uint64 {
	return uint64(len(data))
}

func (s *Storage) SaveFile(data []byte) (*File, error) {
	file := File{
		// AbstractModel: database.AbstractModel{
		// 	CreatedAt: time.Now(),
		// 	UpdatedAt: time.Now(),
		// },
		Hash: s.getHash(data),
	}
	if err := s.repository.Find(&file); err != nil && !errors.Is(err, ErrFileNotFound) {
		return nil, err
	}
	if file.Id != uuid.Nil {
		return &file, nil
	}
	storage, err := s.getStorage(uint64(s.getSize(data)))
	if err != nil {
		return nil, err
	}
	file.Id = uuid.New()
	file.MIME = s.getMime(data)
	file.EXT = s.getEXT(file.MIME)[1:]
	file.Size = s.getSize(data)
	file.Storage = s.getStorageType(storage)
	s.logger.Printf("[Storage] Save file. Storage: %s, Size: %d, Hash: %s", file.Storage, file.Size, file.Hash)
	err = s.repository.Create(&file)
	if err != nil {
		return nil, err
	}
	storage.SaveFile(file.Id, data)
	return &file, nil
}

func (s *Storage) LoadFile(fileId uuid.UUID) ([]byte, error) {
	file, err := s.repository.Retrieve(fileId)
	if err != nil {
		return nil, err
	}
	s.logger.Printf("[Storage] Load file. Storage: %s, Size: %d, Hash: %s", file.Storage, file.Size, file.Hash)
	return s.storages[file.Storage].LoadFile(file.Id)
}

func (s *Storage) DeleteFile(fileId uuid.UUID) error {
	file, err := s.repository.Retrieve(fileId)
	if err != nil {
		return err
	}
	s.logger.Printf("[Storage] Delete file. Storage: %s, Size: %d, Hash: %s", file.Storage, file.Size, file.Hash)
	return s.storages[file.Storage].DeleteFile(file.Id)
}
