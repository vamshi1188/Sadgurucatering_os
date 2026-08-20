package app

import (
	"testing"

	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/config"
)

func TestNew(t *testing.T) {
	application := New(config.Config{
		App: config.AppConfig{
			Name:    "TestApp",
			Version: "1.0.0",
		},
		Environment: "test",
	})

	if application == nil {
		t.Fatal("expected application to be initialized")
	}
}
