package sync

import (
	"cloud-storage/app/utils"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/joho/godotenv"
)

type SyncConfig struct {
	Folders          []string
	Periodicity      time.Duration
	Excludes         bool
	ExcludesRegexp   *regexp.Regexp
	MaxSize          int64
	LastUploadSync   time.Time
	LastDownloadSync time.Time
}

func loadConfig() *SyncConfig {
	duration, err := time.ParseDuration(utils.GetEnv("SYNC_PERIODICITY", "60s"))
	if err != nil {
		duration = 60 * time.Second
	}
	maxSize, err := strconv.ParseInt(utils.GetEnv("SYNC_MAXSIZE", ""), 10, 64)
	if err != nil {
		maxSize = 0
	}
	_ = godotenv.Load("sync.env")
	lastUploadSyncInt, err := strconv.ParseInt(utils.GetEnv("SYNC_LAST_UPLOAD_TIME", "0"), 10, 64)
	if err != nil {
		lastUploadSyncInt = 0
	}
	lastDownloadSyncInt, err := strconv.ParseInt(utils.GetEnv("SYNC_LAST_DOWNLOAD_TIME", "0"), 10, 64)
	if err != nil {
		lastDownloadSyncInt = 0
	}
	return &SyncConfig{
		Folders:          strings.Split(utils.GetEnv("SYNC_FOLDER", ""), ","),
		Periodicity:      duration,
		Excludes:         utils.GetEnv("SYNC_EXCLUDE", "") != "",
		ExcludesRegexp:   regexp.MustCompile("(" + strings.Join(strings.Split(utils.GetEnv("SYNC_EXCLUDE", ""), ","), "|") + ")"),
		MaxSize:          maxSize,
		LastUploadSync:   time.Unix(lastUploadSyncInt, 0),
		LastDownloadSync: time.Unix(lastDownloadSyncInt, 0),
	}
}

func saveConfig(config *SyncConfig) {
	godotenv.Write(map[string]string{
		"SYNC_LAST_UPLOAD_TIME":   strconv.FormatInt(config.LastUploadSync.Unix(), 10),
		"SYNC_LAST_DOWNLOAD_TIME": strconv.FormatInt(config.LastDownloadSync.Unix(), 10),
	}, "sync.env")
}
