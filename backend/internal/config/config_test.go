package config

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func writeTestConfig(t *testing.T, content string) string {
	t.Helper()

	path := filepath.Join(t.TempDir(), "config.toml")

	if err := os.WriteFile(path, []byte(content), 0600); err != nil {
		t.Fatalf("write test config: %v", err)
	}

	return path
}

func validConfigTOML() string {
	return `
[app]
name = "Sadguru Catering OS"
environment = "test"
version = "0.4.0"
log_level = "debug"

[http]
host = "127.0.0.1"
port = 9090
frontend_origin = "http://localhost:3000"

[database]
host = "localhost"
port = 5432
name = "sadguru"
user = "sadguru"
password = "test-password"
ssl_mode = "disable"

[auth]
password = "test-auth-password"
session_secret = "test-session-secret"
secure = false

[shutdown]
timeout = "5s"

[redis]
url = ""

[storage]
endpoint = ""
bucket = ""
access_key = ""
secret_key = ""

[migrations]
path = "migrations"
`
}

func TestLoadFromFile(t *testing.T) {
	path := writeTestConfig(t, validConfigTOML())

	cfg, err := LoadFromFile(path)
	if err != nil {
		t.Fatalf("expected configuration to load, got error: %v", err)
	}

	if cfg.App.Name != "Sadguru Catering OS" {
		t.Fatalf("unexpected app name: %s", cfg.App.Name)
	}

	if cfg.App.Version != "0.4.0" {
		t.Fatalf("unexpected app version: %s", cfg.App.Version)
	}

	if cfg.Environment != "test" {
		t.Fatalf("unexpected environment: %s", cfg.Environment)
	}

	if cfg.LogLevel != "debug" {
		t.Fatalf("unexpected log level: %s", cfg.LogLevel)
	}

	if cfg.HTTP.Host != "127.0.0.1" {
		t.Fatalf("unexpected HTTP host: %s", cfg.HTTP.Host)
	}

	if cfg.HTTP.Port != 9090 {
		t.Fatalf("unexpected HTTP port: %d", cfg.HTTP.Port)
	}

	if cfg.Database.URL != "postgres://sadguru:test-password@localhost:5432/sadguru?sslmode=disable" {
		t.Fatalf("unexpected database URL: %s", cfg.Database.URL)
	}

	if cfg.Auth.Password != "test-auth-password" {
		t.Fatalf("unexpected auth password")
	}

	if cfg.ShutdownTimeout != 5*time.Second {
		t.Fatalf("unexpected shutdown timeout: %v", cfg.ShutdownTimeout)
	}

	if cfg.Migrations.Path != "migrations" {
		t.Fatalf("unexpected migrations path: %s", cfg.Migrations.Path)
	}
}

func TestLoadUsesConfigEnvironmentOverride(t *testing.T) {
	path := writeTestConfig(t, validConfigTOML())

	t.Setenv("SADGURU_CONFIG_FILE", path)

	cfg, err := Load()
	if err != nil {
		t.Fatalf("expected configuration to load, got error: %v", err)
	}

	if cfg.HTTP.Port != 9090 {
		t.Fatalf("expected port 9090, got %d", cfg.HTTP.Port)
	}
}

func TestLoadRejectsMissingFile(t *testing.T) {
	_, err := LoadFromFile("/does/not/exist/config.toml")

	if err == nil {
		t.Fatal("expected missing configuration file error")
	}
}

func TestLoadRejectsInvalidTOML(t *testing.T) {
	path := writeTestConfig(t, "[app\ninvalid")

	_, err := LoadFromFile(path)

	if err == nil {
		t.Fatal("expected TOML parsing error")
	}
}

func TestLoadRejectsInvalidShutdownDuration(t *testing.T) {
	config := validConfigTOML()
	config = strings.Replace(
		config,
		`timeout = "5s"`,
		`timeout = "invalid"`,
		1,
	)

	path := writeTestConfig(t, config)

	_, err := LoadFromFile(path)

	if err == nil {
		t.Fatal("expected shutdown duration error")
	}
}

func TestValidateRejectsMissingAppName(t *testing.T) {
	cfg := Config{
		Environment: "development",
		LogLevel:    "info",
		App: AppConfig{
			Name:    "",
			Version: "0.4.0",
		},
		HTTP: HTTPConfig{
			Host: "0.0.0.0",
			Port: 8080,
		},
		ShutdownTimeout: 10 * time.Second,
	}

	if err := cfg.Validate(); err == nil {
		t.Fatal("expected validation error")
	}
}

func TestValidateRejectsInvalidEnvironment(t *testing.T) {
	cfg := Config{
		Environment: "invalid",
		LogLevel:    "info",
		App: AppConfig{
			Name:    "Sadguru Catering OS",
			Version: "0.4.0",
		},
		HTTP: HTTPConfig{
			Host: "0.0.0.0",
			Port: 8080,
		},
		ShutdownTimeout: 10 * time.Second,
	}

	if err := cfg.Validate(); err == nil {
		t.Fatal("expected validation error")
	}
}

func TestValidateRejectsInvalidLogLevel(t *testing.T) {
	cfg := Config{
		Environment: "development",
		LogLevel:    "trace",
		App: AppConfig{
			Name:    "Sadguru Catering OS",
			Version: "0.4.0",
		},
		HTTP: HTTPConfig{
			Host: "0.0.0.0",
			Port: 8080,
		},
		ShutdownTimeout: 10 * time.Second,
	}

	if err := cfg.Validate(); err == nil {
		t.Fatal("expected validation error")
	}
}

func TestValidateRejectsInvalidHTTPPort(t *testing.T) {
	cfg := Config{
		Environment: "development",
		LogLevel:    "info",
		App: AppConfig{
			Name:    "Sadguru Catering OS",
			Version: "0.4.0",
		},
		HTTP: HTTPConfig{
			Host: "0.0.0.0",
			Port: 70000,
		},
		ShutdownTimeout: 10 * time.Second,
	}

	if err := cfg.Validate(); err == nil {
		t.Fatal("expected validation error")
	}
}

func TestValidateRequiresDatabaseInProduction(t *testing.T) {
	cfg := Config{
		Environment: "production",
		LogLevel:    "info",
		App: AppConfig{
			Name:    "Sadguru Catering OS",
			Version: "0.4.0",
		},
		HTTP: HTTPConfig{
			Host: "0.0.0.0",
			Port: 8080,
		},
		ShutdownTimeout: 10 * time.Second,
	}

	if err := cfg.Validate(); err == nil {
		t.Fatal("expected validation error")
	}
}

func TestConfigStringDoesNotExposeSecrets(t *testing.T) {
	cfg := Config{
		Environment: "development",
		LogLevel:    "info",
		App: AppConfig{
			Name:    "Sadguru Catering OS",
			Version: "0.4.0",
		},
		HTTP: HTTPConfig{
			Host: "0.0.0.0",
			Port: 8080,
		},
		Database: DatabaseConfig{
			URL: "postgres://secret-user:secret-password@localhost/sadguru",
		},
		Storage: StorageConfig{
			AccessKey: "secret-access-key",
			SecretKey: "secret-secret-key",
		},
		ShutdownTimeout: 10 * time.Second,
	}

	value := cfg.String()

	for _, secret := range []string{
		"secret-password",
		"secret-access-key",
		"secret-secret-key",
	} {
		if strings.Contains(value, secret) {
			t.Fatalf("configuration string exposed secret %q", secret)
		}
	}
}

func TestConfigString(t *testing.T) {
	cfg := Config{
		Environment: "test",
		LogLevel:    "debug",
		App: AppConfig{
			Name:    "Test Catering OS",
			Version: "0.4.0",
		},
		HTTP: HTTPConfig{
			Host: "127.0.0.1",
			Port: 9090,
		},
		ShutdownTimeout: 5 * time.Second,
	}

	expected := "app=Test Catering OS version=0.4.0 env=test log_level=debug http=127.0.0.1:9090"

	if cfg.String() != expected {
		t.Fatalf("unexpected configuration string: %s", cfg.String())
	}
}
