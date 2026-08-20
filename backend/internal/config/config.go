package config

import (
	"errors"
	"fmt"
	"os"
	"time"
)

type Config struct {
	App             AppConfig
	HTTP            HTTPConfig
	Database        DatabaseConfig
	Redis           RedisConfig
	Storage         StorageConfig
	Environment     string
	LogLevel        string
	ShutdownTimeout time.Duration
}

type AppConfig struct {
	Name    string
	Version string
}

type HTTPConfig struct {
	Host string
	Port string
}

type DatabaseConfig struct {
	URL string
}

type RedisConfig struct {
	URL string
}

type StorageConfig struct {
	Endpoint  string
	Bucket    string
	AccessKey string
	SecretKey string
}

func Load() (Config, error) {
	cfg := Config{
		Environment: getEnv("APP_ENV", "development"),
		LogLevel:    getEnv("LOG_LEVEL", "info"),

		App: AppConfig{
			Name:    getEnv("APP_NAME", "Sadguru Catering OS"),
			Version: getEnv("APP_VERSION", "1.0.3"),
		},

		HTTP: HTTPConfig{
			Host: getEnv("HTTP_HOST", "0.0.0.0"),
			Port: getEnv("HTTP_PORT", "8080"),
		},

		Database: DatabaseConfig{
			URL: os.Getenv("DATABASE_URL"),
		},

		Redis: RedisConfig{
			URL: os.Getenv("REDIS_URL"),
		},

		Storage: StorageConfig{
			Endpoint:  os.Getenv("STORAGE_ENDPOINT"),
			Bucket:    os.Getenv("STORAGE_BUCKET"),
			AccessKey: os.Getenv("STORAGE_ACCESS_KEY"),
			SecretKey: os.Getenv("STORAGE_SECRET_KEY"),
		},

		ShutdownTimeout: getDurationEnv(
			"SHUTDOWN_TIMEOUT",
			10*time.Second,
		),
	}

	if err := cfg.Validate(); err != nil {
		return Config{}, err
	}

	return cfg, nil
}

func (c Config) Validate() error {
	if c.App.Name == "" {
		return errors.New("APP_NAME cannot be empty")
	}

	if c.App.Version == "" {
		return errors.New("APP_VERSION cannot be empty")
	}

	if c.Environment == "" {
		return errors.New("APP_ENV cannot be empty")
	}

	if c.HTTP.Host == "" {
		return errors.New("HTTP_HOST cannot be empty")
	}

	if c.HTTP.Port == "" {
		return errors.New("HTTP_PORT cannot be empty")
	}

	return nil
}

func getEnv(key, fallback string) string {
	value := os.Getenv(key)

	if value == "" {
		return fallback
	}

	return value
}

func (c Config) String() string {
	return fmt.Sprintf(
		"app=%s version=%s env=%s http=%s:%s",
		c.App.Name,
		c.App.Version,
		c.Environment,
		c.HTTP.Host,
		c.HTTP.Port,
	)
}

func getDurationEnv(key string, fallback time.Duration) time.Duration {
	value := os.Getenv(key)

	if value == "" {
		return fallback
	}

	duration, err := time.ParseDuration(value)
	if err != nil {
		return fallback
	}

	return duration
}
