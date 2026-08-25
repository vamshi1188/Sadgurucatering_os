package main

import (
	"fmt"
	"log"
	"os"

	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/migrations"
)

func main() {
	databaseURL := os.Getenv("DATABASE_URL")

	if databaseURL == "" {
		log.Fatal("DATABASE_URL is required")
	}

	migrationPath := os.Getenv("MIGRATIONS_PATH")

	if migrationPath == "" {
		migrationPath = "/app/migrations"
	}

	if len(os.Args) < 2 {
		log.Fatal("migration command is required: up or down")
	}

	switch os.Args[1] {
	case "up":
		if err := migrations.Up(databaseURL, migrationPath); err != nil {
			log.Fatal(err)
		}

	case "down":
		if err := migrations.Down(databaseURL, migrationPath); err != nil {
			log.Fatal(err)
		}

	default:
		log.Fatal(fmt.Sprintf("unknown migration command: %s", os.Args[1]))
	}
}
