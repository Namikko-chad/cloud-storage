package sync

import (
	"os"
	"time"
)

func (sp *SyncPackage) loadFileFromDisk(filename string) ([]byte, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}
	return data, nil
}

func (sp *SyncPackage) saveFileToDisk(filename string, data []byte, modifiedAt time.Time) error {
	if _, err := os.Stat(filename); err == nil {
		err = os.Remove(filename)
		if err != nil {
			return err
		}
	}
	err := os.WriteFile(filename, data, 0644)
	if err != nil {
		return err
	}
	err = os.Chtimes(filename, time.Now(), modifiedAt)
	if err != nil {
		return err
	}
	return nil
}
