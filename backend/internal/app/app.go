package app

import (
	"fmt"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/config"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/httpserver"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/router"
)

type App struct {
	Config     config.Config
	HTTPServer *httpserver.Server
}

func New(cfg config.Config) *App {
	handler := router.New()

	return &App{
		Config: cfg,
		HTTPServer: httpserver.New(
			cfg.HTTP.Host,
			cfg.HTTP.Port,
			handler,
		),
	}
}

func (a *App) Run() error {
	fmt.Printf(
		"Starting %s v%s [%s]\n",
		a.Config.App.Name,
		a.Config.App.Version,
		a.Config.Environment,
	)

	return a.HTTPServer.Start()
}
