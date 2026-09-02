package config

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/BurntSushi/toml"
)

type Config struct {
	App             AppConfig
	HTTP            HTTPConfig
	Database        DatabaseConfig
	Redis           RedisConfig
	Storage         StorageConfig
	Auth            AuthConfig
	Migrations      MigrationsConfig
	ShutdownTimeout time.Duration
	Environment     string
	LogLevel        string
}

type AppConfig struct {
	Name        string `toml:"name"`
	Version     string `toml:"version"`
	Environment string `toml:"environment"`
	LogLevel    string `toml:"log_level"`
}

type HTTPConfig struct {
	Host           string `toml:"host"`
	Port           int    `toml:"port"`
	FrontendOrigin string `toml:"frontend_origin"`
}

type DatabaseConfig struct {
	Host     string `toml:"host"`
	Port     int    `toml:"port"`
	Name     string `toml:"name"`
	User     string `toml:"user"`
	Password string `toml:"password"`
	SSLMode  string `toml:"ssl_mode"`

	// URL is constructed from the structured database settings.
	URL string `toml:"-"`
}

type RedisConfig struct {
	URL string `toml:"url"`
}

type StorageConfig struct {
	Endpoint  string `toml:"endpoint"`
	Bucket    string `toml:"bucket"`
	AccessKey string `toml:"access_key"`
	SecretKey string `toml:"secret_key"`
}

type AuthConfig struct {
	Password string `toml:"password"`
	Secret   string `toml:"session_secret"`
	Secure   bool   `toml:"secure"`
}

type MigrationsConfig struct {
	Path string `toml:"path"`
}

type ShutdownConfig struct {
	Timeout string `toml:"timeout"`
}

type rawConfig struct {
	App        AppConfig        `toml:"app"`
	HTTP       HTTPConfig       `toml:"http"`
	Database   DatabaseConfig   `toml:"database"`
	Auth       AuthConfig       `toml:"auth"`
	Shutdown   ShutdownConfig   `toml:"shutdown"`
	Redis      RedisConfig      `toml:"redis"`
	Storage    StorageConfig    `toml:"storage"`
	Migrations MigrationsConfig `toml:"migrations"`
}

func Load() (Config, error) {
	path := configPath()

	return LoadFromFile(path)
}

func LoadFromFile(path string) (Config, error) {
	if path == "" {
		return Config{}, errors.New("configuration file path cannot be empty")
	}

	var raw rawConfig

	if _, err := toml.DecodeFile(path, &raw); err != nil {
		return Config{}, fmt.Errorf("load configuration file %q: %w", path, err)
	}

	shutdownTimeout, err := time.ParseDuration(raw.Shutdown.Timeout)
	if err != nil {
		return Config{}, fmt.Errorf(
			"shutdown.timeout: invalid duration %q: %w",
			raw.Shutdown.Timeout,
			err,
		)
	}

	cfg := Config{
		App:             raw.App,
		HTTP:            raw.HTTP,
		Database:        raw.Database,
		Redis:           raw.Redis,
		Storage:         raw.Storage,
		Auth:            raw.Auth,
		Migrations:      raw.Migrations,
		ShutdownTimeout: shutdownTimeout,
		Environment:     raw.App.Environment,
		LogLevel:        raw.App.LogLevel,
	}

	cfg.Database.URL = buildDatabaseURL(cfg.Database)

	if err := cfg.Validate(); err != nil {
		return Config{}, err
	}

	return cfg, nil
}

func configPath() string {
	if value := os.Getenv("SADGURU_CONFIG_FILE"); value != "" {
		return value
	}

	candidates := []string{
		"config/config.toml",
		"backend/config/config.toml",
	}

	for _, candidate := range candidates {
		if _, err := os.Stat(candidate); err == nil {
			return candidate
		}
	}

	if executable, err := os.Executable(); err == nil {
		base := filepath.Dir(executable)
		candidate := filepath.Join(base, "config", "config.toml")

		if _, err := os.Stat(candidate); err == nil {
			return candidate
		}
	}

	return "config/config.toml"
}

func buildDatabaseURL(database DatabaseConfig) string {
	if database.Host == "" ||
		database.Port == 0 ||
		database.Name == "" ||
		database.User == "" {
		return ""
	}

	return fmt.Sprintf(
		"postgres://%s:%s@%s:%d/%s?sslmode=%s",
		database.User,
		database.Password,
		database.Host,
		database.Port,
		database.Name,
		database.SSLMode,
	)
}

func (c Config) Validate() error {
	if c.App.Name == "" {
		return errors.New("app.name cannot be empty")
	}

	if c.App.Version == "" {
		return errors.New("app.version cannot be empty")
	}

	switch c.Environment {
	case "development", "test", "production":
	default:
		return fmt.Errorf(
			"app.environment must be one of development, test, production; got %q",
			c.Environment,
		)
	}

	switch c.LogLevel {
	case "debug", "info", "warn", "error":
	default:
		return fmt.Errorf(
			"app.log_level must be one of debug, info, warn, error; got %q",
			c.LogLevel,
		)
	}

	if c.HTTP.Host == "" {
		return errors.New("http.host cannot be empty")
	}

	if c.HTTP.Port < 1 || c.HTTP.Port > 65535 {
		return fmt.Errorf(
			"http.port must be between 1 and 65535; got %d",
			c.HTTP.Port,
		)
	}

	if c.ShutdownTimeout <= 0 {
		return errors.New("shutdown.timeout must be greater than zero")
	}

	if c.Migrations.Path == "" {
		return errors.New("migrations.path cannot be empty")
	}

	if c.Environment == "production" && c.Database.URL == "" {
		return errors.New("database configuration is required in production")
	}

	return nil
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
