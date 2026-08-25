package app

import (
	"fmt"

	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/config"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/db"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/httpserver"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/logger"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/middleware"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/router"
)

type App struct {
	Config     config.Config
	Logger     *logger.Logger
	HTTPServer *httpserver.Server
	DB         *db.DB
}

func New(cfg config.Config) *App {
	handler := router.New()

	appLogger := logger.New(nil, cfg.LogLevel)

	handler = middleware.Chain(
		handler,
		middleware.RequestID,
		middleware.Recovery,
		middleware.SecurityHeaders,
		middleware.RequestLogger(appLogger),
	)

	return &App{
		Config: cfg,
		Logger: appLogger,
		HTTPServer: httpserver.New(
			cfg.HTTP.Host,
			cfg.HTTP.Port,
			handler,
		),
	}
}

func (a *App) Run() error {
	a.Logger.Info(
		"application starting",
		"app", a.Config.App.Name,
		"version", a.Config.App.Version,
		"environment", a.Config.Environment,
		"host", a.Config.HTTP.Host,
		"port", a.Config.HTTP.Port,
	)

	if a.Config.Database.URL == "" {
		return fmt.Errorf("database configuration is required")
	}

	database, err := db.Open(a.Config.Database.URL)
	if err != nil {
		return fmt.Errorf("initialize database: %w", err)
	}

	a.DB = database

	a.Logger.Info("database connection established")

	go func() {
		if err := a.HTTPServer.Start(); err != nil {
			a.Logger.ErrorWithCause(
				"http server stopped unexpectedly",
				err,
			)
		}
	}()

	signal := waitForShutdownSignal()

	a.Logger.Info(
		"shutdown signal received",
		"signal", signal.String(),
	)

	return a.shutdown()
}
