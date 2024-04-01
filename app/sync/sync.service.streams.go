package sync

func (sp *SyncPackage) downloads() {
	for file := range sp.downloadStream {
		sp.downloadFromStorage(file)
		sp.server.Logger.Printf("[Sync.downloads] Downloaded file. Hash: %s", file.Hash)
	}

	sp.server.Logger.Println("[Sync.downloads] Download stream stopped")
}

func (sp *SyncPackage) uploads() {
	for file := range sp.uploadStream {
		sp.uploadToStorage(file)
		sp.server.Logger.Printf("[Sync.uploads] Uploaded file. Hash: %s", file.Hash)
	}

	sp.server.Logger.Println("[Sync.uploads] Upload stream stopped")
}
