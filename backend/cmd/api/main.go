package main

import (
	"log"

	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/app"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/config"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("failed to load configuration: %v", err)
	}

	application := app.New(cfg)

	if err := application.Run(); err != nil {
		log.Fatalf("application stopped: %v", err)
	}
}
