package config

import (
	"os"
	"testing"
)

func TestLoadDefaults(t *testing.T) {
	t.Setenv("APP_ENV", "")
	t.Setenv("APP_NAME", "")
	t.Setenv("APP_VERSION", "")
	t.Setenv("HTTP_HOST", "")
	t.Setenv("HTTP_PORT", "")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("expected configuration to load, got error: %v", err)
	}

	if cfg.App.Name != "Sadguru Catering OS" {
		t.Fatalf("unexpected app name: %s", cfg.App.Name)
	}

	if cfg.Environment != "development" {
		t.Fatalf("unexpected environment: %s", cfg.Environment)
	}

	if cfg.HTTP.Port != "8080" {
		t.Fatalf("unexpected HTTP port: %s", cfg.HTTP.Port)
	}
}

func TestLoadEnvironmentVariables(t *testing.T) {
	t.Setenv("APP_ENV", "test")
	t.Setenv("APP_NAME", "Test Catering OS")
	t.Setenv("APP_VERSION", "1.0.3")
	t.Setenv("HTTP_HOST", "127.0.0.1")
	t.Setenv("HTTP_PORT", "9090")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("expected configuration to load, got error: %v", err)
	}

	if cfg.Environment != "test" {
		t.Fatalf("unexpected environment: %s", cfg.Environment)
	}

	if cfg.App.Name != "Test Catering OS" {
		t.Fatalf("unexpected app name: %s", cfg.App.Name)
	}

	if cfg.HTTP.Port != "9090" {
		t.Fatalf("unexpected HTTP port: %s", cfg.HTTP.Port)
	}
}

func TestValidateRejectsMissingAppName(t *testing.T) {
	cfg := Config{
		Environment: "development",
		App: AppConfig{
			Name:    "",
			Version: "1.0.3",
		},
		HTTP: HTTPConfig{
			Host: "0.0.0.0",
			Port: "8080",
		},
	}

	if err := cfg.Validate(); err == nil {
		t.Fatal("expected validation error")
	}
}

func TestSensitiveEnvironmentVariablesAreNotRequired(t *testing.T) {
	_ = os.Unsetenv("DATABASE_URL")
	_ = os.Unsetenv("REDIS_URL")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("expected configuration to load without database/redis, got: %v", err)
	}

	if cfg.Database.URL != "" {
		t.Fatal("expected empty database URL")
	}

	if cfg.Redis.URL != "" {
		t.Fatal("expected empty redis URL")
	}
}
