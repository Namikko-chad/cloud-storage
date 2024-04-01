package sync

import (
	"fmt"

	"github.com/google/uuid"
)

func (sp *SyncPackage) uploadToStorage(file CloudFile) {
	fileData, err := sp.loadFileFromDisk(fmt.Sprintf("%s/%s", file.Path, file.Name))
	if err != nil {
		return
	}
	storagedFile, err := sp.storage.SaveFile(fileData)
	if err != nil {
		return
	}
	sp.server.Logger.Printf("[Sync.uploadToStorage] Saved file. Size: %d, Hash: %s", storagedFile.Size, storagedFile.Hash)
	if file.Id != uuid.Nil {
		sp.repository.Delete(&file)
	}
	sp.repository.Create(&CloudFile{
		FileId:     storagedFile.Id,
		Path:       file.Path,
		Name:       file.Name,
		Hash:       storagedFile.Hash,
		ModifiedAt: file.ModifiedAt,
	})
}

func (sp *SyncPackage) downloadFromStorage(file CloudFile) {
	fileData, err := sp.storage.LoadFile(file.FileId)
	if err != nil {
		sp.server.Logger.Printf("[Sync.downloadFromStorage] Can't load file. Error: %s", err.Error())
		return
	}
	err = sp.saveFileToDisk(fmt.Sprintf("%s/%s", file.Path, file.Name), fileData, file.ModifiedAt)
	if err != nil {
		sp.server.Logger.Printf("[Sync.downloadFromStorage] Can't save file. Error: %s", err.Error())
		return
	}
	sp.server.Logger.Printf("[Sync.downloadFromStorage] Downloaded file. Size: %d, Hash: %s", len(fileData), file.Hash)
}
