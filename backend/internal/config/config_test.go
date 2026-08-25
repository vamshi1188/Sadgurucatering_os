package config

import (
	"os"
	"testing"
	"time"
)

func TestLoadDefaults(t *testing.T) {
	t.Setenv("APP_ENV", "")
	t.Setenv("APP_NAME", "")
	t.Setenv("APP_VERSION", "")
	t.Setenv("LOG_LEVEL", "")
	t.Setenv("HTTP_HOST", "")
	t.Setenv("HTTP_PORT", "")
	t.Setenv("DATABASE_URL", "")
	t.Setenv("SHUTDOWN_TIMEOUT", "")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("expected configuration to load, got error: %v", err)
	}

	if cfg.App.Name != "Sadguru Catering OS" {
		t.Fatalf("unexpected app name: %s", cfg.App.Name)
	}

	if cfg.App.Version != "1.0.7" {
		t.Fatalf("unexpected app version: %s", cfg.App.Version)
	}

	if cfg.Environment != "development" {
		t.Fatalf("unexpected environment: %s", cfg.Environment)
	}

	if cfg.LogLevel != "info" {
		t.Fatalf("unexpected log level: %s", cfg.LogLevel)
	}

	if cfg.HTTP.Host != "0.0.0.0" {
		t.Fatalf("unexpected HTTP host: %s", cfg.HTTP.Host)
	}

	if cfg.HTTP.Port != 8080 {
		t.Fatalf("unexpected HTTP port: %d", cfg.HTTP.Port)
	}

	if cfg.ShutdownTimeout != 10*time.Second {
		t.Fatalf(
			"unexpected shutdown timeout: %v",
			cfg.ShutdownTimeout,
		)
	}
}

func TestLoadEnvironmentVariables(t *testing.T) {
	t.Setenv("APP_ENV", "test")
	t.Setenv("APP_NAME", "Test Catering OS")
	t.Setenv("APP_VERSION", "1.0.7-test")
	t.Setenv("LOG_LEVEL", "debug")
	t.Setenv("HTTP_HOST", "127.0.0.1")
	t.Setenv("HTTP_PORT", "9090")
	t.Setenv("DATABASE_URL", "postgres://test")
	t.Setenv("SHUTDOWN_TIMEOUT", "5s")

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

	if cfg.App.Version != "1.0.7-test" {
		t.Fatalf("unexpected app version: %s", cfg.App.Version)
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

	if cfg.Database.URL != "postgres://test" {
		t.Fatalf("unexpected database URL: %s", cfg.Database.URL)
	}

	if cfg.ShutdownTimeout != 5*time.Second {
		t.Fatalf(
			"unexpected shutdown timeout: %v",
			cfg.ShutdownTimeout,
		)
	}
}

func TestValidateRejectsMissingAppName(t *testing.T) {
	cfg := Config{
		Environment: "development",
		LogLevel:    "info",
		App: AppConfig{
			Name:    "",
			Version: "1.0.7",
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
			Version: "1.0.7",
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
			Version: "1.0.7",
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
			Version: "1.0.7",
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
			Version: "1.0.7",
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

func TestSensitiveEnvironmentVariablesAreNotRequired(t *testing.T) {
	t.Setenv("DATABASE_URL", "")
	t.Setenv("REDIS_URL", "")
	t.Setenv("STORAGE_ENDPOINT", "")
	t.Setenv("STORAGE_BUCKET", "")
	t.Setenv("STORAGE_ACCESS_KEY", "")
	t.Setenv("STORAGE_SECRET_KEY", "")

	cfg, err := Load()
	if err != nil {
		t.Fatalf(
			"expected configuration to load without optional services, got: %v",
			err,
		)
	}

	if cfg.Database.URL != "" {
		t.Fatal("expected empty database URL")
	}

	if cfg.Redis.URL != "" {
		t.Fatal("expected empty redis URL")
	}

	if cfg.Storage.Endpoint != "" {
		t.Fatal("expected empty storage endpoint")
	}

	if cfg.Storage.AccessKey != "" {
		t.Fatal("expected empty storage access key")
	}

	if cfg.Storage.SecretKey != "" {
		t.Fatal("expected empty storage secret key")
	}
}

func TestGetIntEnv(t *testing.T) {
	t.Setenv("TEST_PORT", "9090")

	value, err := getIntEnv("TEST_PORT", 8080)
	if err != nil {
		t.Fatalf("expected integer to parse, got error: %v", err)
	}

	if value != 9090 {
		t.Fatalf("expected 9090, got %d", value)
	}
}

func TestGetIntEnvFallback(t *testing.T) {
	t.Setenv("TEST_PORT", "")

	value, err := getIntEnv("TEST_PORT", 8080)
	if err != nil {
		t.Fatalf("expected fallback without error, got: %v", err)
	}

	if value != 8080 {
		t.Fatalf("expected fallback 8080, got %d", value)
	}
}

func TestGetIntEnvRejectsInvalidValue(t *testing.T) {
	t.Setenv("TEST_PORT", "invalid")

	_, err := getIntEnv("TEST_PORT", 8080)
	if err == nil {
		t.Fatal("expected integer parsing error")
	}
}

func TestGetDurationEnv(t *testing.T) {
	t.Setenv("TEST_DURATION", "5s")

	duration, err := getDurationEnv(
		"TEST_DURATION",
		10*time.Second,
	)

	if err != nil {
		t.Fatalf("expected duration to parse, got error: %v", err)
	}

	if duration != 5*time.Second {
		t.Fatalf(
			"expected 5s, got %v",
			duration,
		)
	}
}

func TestGetDurationEnvFallback(t *testing.T) {
	t.Setenv("TEST_DURATION", "")

	duration, err := getDurationEnv(
		"TEST_DURATION",
		10*time.Second,
	)

	if err != nil {
		t.Fatalf("expected fallback without error, got: %v", err)
	}

	if duration != 10*time.Second {
		t.Fatalf(
			"expected fallback 10s, got %v",
			duration,
		)
	}
}

func TestGetDurationEnvRejectsInvalidValue(t *testing.T) {
	t.Setenv("TEST_DURATION", "invalid")

	_, err := getDurationEnv(
		"TEST_DURATION",
		10*time.Second,
	)

	if err == nil {
		t.Fatal("expected duration parsing error")
	}
}

func TestConfigStringDoesNotExposeSecrets(t *testing.T) {
	cfg := Config{
		Environment: "development",
		LogLevel:    "info",
		App: AppConfig{
			Name:    "Sadguru Catering OS",
			Version: "1.0.7",
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
		if contains(value, secret) {
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
			Version: "1.0.7",
		},
		HTTP: HTTPConfig{
			Host: "127.0.0.1",
			Port: 9090,
		},
		ShutdownTimeout: 5 * time.Second,
	}

	expected := "app=Test Catering OS version=1.0.7 env=test log_level=debug http=127.0.0.1:9090"

	if cfg.String() != expected {
		t.Fatalf(
			"unexpected configuration string: %s",
			cfg.String(),
		)
	}
}

func contains(value, target string) bool {
	return len(target) > 0 && len(value) >= len(target) &&
		stringContains(value, target)
}

func stringContains(value, target string) bool {
	for i := 0; i <= len(value)-len(target); i++ {
		if value[i:i+len(target)] == target {
			return true
		}
	}

	return false
}

func TestSensitiveEnvironmentVariablesAreNotRequiredUsesOS(t *testing.T) {
	_ = os.Unsetenv("DATABASE_URL")
	_ = os.Unsetenv("REDIS_URL")
}
