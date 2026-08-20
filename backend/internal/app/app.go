package app

import "fmt"

type App struct{}

func New() *App {
	return &App{}
}

func (a *App) Run() {
	fmt.Println("Sadguru Catering OS API")
}
