package migrations

import (
	"fmt"
	"net/url"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
)

func Up(databaseURL, migrationsPath string) error {
	if databaseURL == "" {
		return fmt.Errorf("database URL is required")
	}

	if migrationsPath == "" {
		return fmt.Errorf("migrations path is required")
	}

	sourceURL := (&url.URL{
		Scheme: "file",
		Path:   migrationsPath,
	}).String()

	migration, err := migrate.New(
		sourceURL,
		databaseURL,
	)
	if err != nil {
		return fmt.Errorf("initialize migration: %w", err)
	}

	defer func() {
		_, _ = migration.Close()
	}()

	if err := migration.Up(); err != nil && err != migrate.ErrNoChange {
		return fmt.Errorf("run migrations: %w", err)
	}

	return nil
}
func Down(databaseURL, migrationsPath string) error {
	if databaseURL == "" {
		return fmt.Errorf("database URL is required")
	}

	if migrationsPath == "" {
		return fmt.Errorf("migrations path is required")
	}

	sourceURL := (&url.URL{
		Scheme: "file",
		Path:   migrationsPath,
	}).String()

	migration, err := migrate.New(
		sourceURL,
		databaseURL,
	)
	if err != nil {
		return fmt.Errorf("initialize migration: %w", err)
	}

	defer func() {
		_, _ = migration.Close()
	}()

	if err := migration.Steps(-1); err != nil && err != migrate.ErrNoChange {
		return fmt.Errorf("rollback migration: %w", err)
	}

	return nil
}
