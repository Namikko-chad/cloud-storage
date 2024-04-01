package database

import (
	"log"
	"time"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func ConnectDB(log *log.Logger) *gorm.DB {
	configLogger := logger.Config{
		SlowThreshold:             time.Second, // Slow SQL threshold
		LogLevel:                  logger.Warn, // Log level
		IgnoreRecordNotFoundError: true,        // Ignore ErrRecordNotFound error for logger
		ParameterizedQueries:      false,        // Don't include params in the SQL log
		Colorful:                  true,        // Disable color
	}
	if DataBaseConfig.Log {
		configLogger.LogLevel = logger.Info
	}
	configGorm := &gorm.Config{
		NamingStrategy: CustomNamingStrategy{},
		Logger:         logger.New(log, configLogger),
	}
	if db, err := gorm.Open(postgres.Open(DataBaseConfig.Link), configGorm); err != nil {
		log.Panic("[Database] Failed to connect", err)
		panic("Failed to connect database")
	} else {
		log.Print("[Database] Connected to database successfully")
		return db
	}
}
