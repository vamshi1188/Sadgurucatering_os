package app

import (
	"context"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func waitForShutdownSignal() os.Signal {
	signalChannel := make(chan os.Signal, 1)

	signal.Notify(
		signalChannel,
		os.Interrupt,
		syscall.SIGTERM,
	)

	return <-signalChannel
}

func (a *App) shutdown() error {
	timeout := a.Config.ShutdownTimeout

	if timeout <= 0 {
		timeout = 10 * time.Second
	}

	a.Logger.Info(
		"graceful shutdown starting",
		"timeout", timeout.String(),
	)

	ctx, cancel := context.WithTimeout(
		context.Background(),
		timeout,
	)
	defer cancel()

	if err := a.HTTPServer.Shutdown(ctx); err != nil {
		a.Logger.ErrorWithCause(
			"graceful shutdown failed",
			err,
		)

		return err
	}

	if a.DB != nil {
		if err := a.DB.Close(); err != nil {
			a.Logger.ErrorWithCause(
				"database shutdown failed",
				err,
			)

			return err
		}
	}

	a.Logger.Info(
		"graceful shutdown completed",
	)

	return nil
}
