package app

import (
	"fmt"

	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/config"
)

type App struct {
	Config config.Config
}

func New(cfg config.Config) *App {
	return &App{
		Config: cfg,
	}
}

func (a *App) Run() {
	fmt.Printf(
		"Starting %s v%s [%s]\n",
		a.Config.App.Name,
		a.Config.App.Version,
		a.Config.Environment,
	)
}
