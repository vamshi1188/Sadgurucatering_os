package config

import (
	"errors"
	"fmt"
	"os"
	"strconv"
	"time"
)

type Config struct {
	App             AppConfig
	HTTP            HTTPConfig
	Database        DatabaseConfig
	Redis           RedisConfig
	Storage         StorageConfig
	Auth            AuthConfig
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
	Port int
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

type AuthConfig struct {
	Password string
	Secret   string
	Secure   bool
}

func Load() (Config, error) {
	port, err := getIntEnv("HTTP_PORT", 8080)
	if err != nil {
		return Config{}, fmt.Errorf("HTTP_PORT: %w", err)
	}

	shutdownTimeout, err := getDurationEnv(
		"SHUTDOWN_TIMEOUT",
		10*time.Second,
	)
	if err != nil {
		return Config{}, fmt.Errorf("SHUTDOWN_TIMEOUT: %w", err)
	}

	cfg := Config{
		Environment: getEnv("APP_ENV", "development"),
		LogLevel:    getEnv("LOG_LEVEL", "info"),

		App: AppConfig{
			Name:    getEnv("APP_NAME", "Sadguru Catering OS"),
			Version: getEnv("APP_VERSION", "1.0.10"),
		},

		HTTP: HTTPConfig{
			Host: getEnv("HTTP_HOST", "0.0.0.0"),
			Port: port,
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

		Auth: AuthConfig{
			Password: os.Getenv("MVP_AUTH_PASSWORD"),
			Secret:   os.Getenv("MVP_AUTH_SESSION_SECRET"),
			Secure:   getEnv("MVP_AUTH_COOKIE_SECURE", "false") == "true",
		},

		ShutdownTimeout: shutdownTimeout,
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

	switch c.Environment {
	case "development", "test", "production":
	default:
		return fmt.Errorf(
			"APP_ENV must be one of development, test, production; got %q",
			c.Environment,
		)
	}

	switch c.LogLevel {
	case "debug", "info", "warn", "error":
	default:
		return fmt.Errorf(
			"LOG_LEVEL must be one of debug, info, warn, error; got %q",
			c.LogLevel,
		)
	}

	if c.HTTP.Host == "" {
		return errors.New("HTTP_HOST cannot be empty")
	}

	if c.HTTP.Port < 1 || c.HTTP.Port > 65535 {
		return fmt.Errorf(
			"HTTP_PORT must be between 1 and 65535; got %d",
			c.HTTP.Port,
		)
	}

	if c.ShutdownTimeout <= 0 {
		return errors.New("SHUTDOWN_TIMEOUT must be greater than zero")
	}

	if c.Environment == "production" && c.Database.URL == "" {
		return errors.New("DATABASE_URL cannot be empty in production")
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

func getIntEnv(key string, fallback int) (int, error) {
	value := os.Getenv(key)

	if value == "" {
		return fallback, nil
	}

	parsed, err := strconv.Atoi(value)
	if err != nil {
		return 0, fmt.Errorf(
			"must be a valid integer; got %q",
			value,
		)
	}

	return parsed, nil
}

func (c Config) String() string {
	return fmt.Sprintf(
		"app=%s version=%s env=%s log_level=%s http=%s:%d",
		c.App.Name,
		c.App.Version,
		c.Environment,
		c.LogLevel,
		c.HTTP.Host,
		c.HTTP.Port,
	)
}

func getDurationEnv(
	key string,
	fallback time.Duration,
) (time.Duration, error) {
	value := os.Getenv(key)

	if value == "" {
		return fallback, nil
	}

	duration, err := time.ParseDuration(value)
	if err != nil {
		return 0, fmt.Errorf(
			"must be a valid duration; got %q",
			value,
		)
	}

	return duration, nil
}
