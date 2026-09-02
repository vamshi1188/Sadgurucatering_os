package app

import (
	"fmt"
	"net/http"

	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/auth"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/config"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/db"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/events"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/finance"
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
	Auth       *auth.Handler
}

func New(cfg config.Config) *App {
	appLogger := logger.New(nil, cfg.LogLevel)

	authHandler := auth.New(auth.Config{
		Password: cfg.Auth.Password,
		Secret:   cfg.Auth.Secret,
		Secure:   cfg.Auth.Secure,
	})

	handler := buildHTTPHandler(authHandler, nil, nil, appLogger, cfg.HTTP.FrontendOrigin)

	return &App{
		Config: cfg,
		Logger: appLogger,
		Auth:   authHandler,
		HTTPServer: httpserver.New(
			cfg.HTTP.Host,
			cfg.HTTP.Port,
			handler,
		),
	}
}

func buildHTTPHandler(
	authHandler *auth.Handler,
	eventHandler *events.Handler,
	financeHandler *finance.Handler,
	appLogger *logger.Logger,
	frontendOrigin string,
) http.Handler {
	handler := router.NewWithFinance(authHandler, eventHandler, financeHandler)

	return middleware.Chain(
		handler,
		middleware.RequestID,
		middleware.Recovery,
		middleware.SecurityHeaders,
		middleware.CORS(frontendOrigin),
		middleware.RequestLogger(appLogger),
	)
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

	eventRepository := events.NewRepository(a.DB.SQL)
	eventService := events.NewService(eventRepository)
	eventHandler := events.NewHandler(eventService)

	financeRepository := finance.NewRepository(a.DB.SQL)
	financeService := finance.NewService(financeRepository)
	financeHandler := finance.NewHandler(financeService)

	handler := buildHTTPHandler(
		a.Auth,
		eventHandler,
		financeHandler,
		a.Logger,
		a.Config.HTTP.FrontendOrigin,
	)

	a.HTTPServer = httpserver.New(
		a.Config.HTTP.Host,
		a.Config.HTTP.Port,
		handler,
	)

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
