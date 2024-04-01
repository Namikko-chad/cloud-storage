package sync

import (
	"context"
	"crypto/md5"
	"encoding/hex"
	"fmt"
	"io/fs"
	"os"
	"time"

	interfaces "cloud-storage/app/interfaces"

	"github.com/google/uuid"
)

func (sp *SyncPackage) filterForDirectories(file fs.FileInfo) bool {
	if sp.config.Excludes && sp.config.ExcludesRegexp.MatchString(file.Name()) {
		sp.server.Logger.Printf("skip by part of name or path, %s\r\n", file.Name())
		return false
	}
	if sp.config.MaxSize != 0 && file.Size() > sp.config.MaxSize {
		sp.server.Logger.Printf("skip by size, %s, size: %d\r\n", file.Name(), file.Size())
		return false
	}
	return true
}

func (sp *SyncPackage) scanDirectories(ctx context.Context) {
	for {
		select {
		case <-ctx.Done():
			return
		default:

			stack := interfaces.Stack{}
			stack = sp.config.Folders
			var dir string
			dir = stack.Pop()
			for dir != "" {
				files, _ := os.ReadDir(dir)
				for _, file := range files {
					fileInfo, _ := file.Info()
					if !sp.filterForDirectories(fileInfo) {
						continue
					}
					if file.IsDir() {
						stack.Push(fmt.Sprintf("%s/%s", dir, file.Name()))
						continue
					}
					data, err := os.ReadFile(fmt.Sprintf("%s/%s", dir, file.Name()))
					if err != nil {
						// TODO added list with file errors
						continue
					}
					var hash = md5.Sum(data)
					file := CloudFile{
						Path:       dir,
						Name:       file.Name(),
						Hash:       hex.EncodeToString(hash[:]),
						ModifiedAt: fileInfo.ModTime(),
					}
					cloudFile := CloudFile{
						Path: file.Path,
						Name: file.Name,
					}
					sp.repository.Find(&cloudFile)
					// File is not exist in DB
					if cloudFile.Id == uuid.Nil {
						sp.server.Logger.Printf("[Sync.Sync] Upload new file. Path: %s, Name: %s, Hash: %s", file.Path, file.Name, file.Hash)
						sp.uploadStream <- file
						continue
					}
					if cloudFile.Hash != file.Hash && file.ModifiedAt.After(cloudFile.ModifiedAt) {
						sp.server.Logger.Printf("[Sync.Sync] Upload updated file. Path: %s, Name: %s, Hash: %s", file.Path, file.Name, file.Hash)
						sp.uploadStream <- cloudFile
						continue
					}
				}
				dir = stack.Pop()
			}
		}
		sp.repository.GetServerTime(&sp.config.LastUploadSync)
		time.Sleep(sp.config.Periodicity)
	}
}

func (sp *SyncPackage) scanCloudStorage(ctx context.Context) {
	for {
		select {
		case <-ctx.Done():
			return
		default:
			var modifiedFiles []CloudFile
			err := sp.repository.FindCreated(&modifiedFiles, sp.config.LastDownloadSync)
			if err != nil {
				sp.server.Logger.Panicf("[Sync.ScanCloudStorage] Can't scan cloud storage. Error: %s", err)
			}
			sp.repository.GetServerTime(&sp.config.LastDownloadSync)
			for _, cloudFile := range modifiedFiles {
				sp.server.Logger.Printf("[Sync.Sync] Download modified file. Path: %s, Name: %s, Hash: %s, ModifiedAt: %s", cloudFile.Path, cloudFile.Name, cloudFile.Hash, cloudFile.ModifiedAt)
				sp.downloadStream <- cloudFile
			}
		}
		time.Sleep(sp.config.Periodicity)
	}
}

func (sp *SyncPackage) Sync() {
	go sp.scanDirectories(sp.ctx)
	go sp.scanCloudStorage(sp.ctx)
}
