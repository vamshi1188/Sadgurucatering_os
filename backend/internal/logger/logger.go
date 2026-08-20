package logger

import (
	"io"
	"log/slog"
	"os"
	"strings"
)

type Logger struct {
	*slog.Logger
}

func New(w io.Writer, level string) *Logger {
	if w == nil {
		w = os.Stdout
	}

	logLevel := parseLevel(level)

	options := &slog.HandlerOptions{
		Level: logLevel,
	}

	return &Logger{
		Logger: slog.New(
			slog.NewJSONHandler(w, options),
		),
	}
}

func parseLevel(level string) slog.Level {
	switch strings.ToLower(level) {
	case "debug":
		return slog.LevelDebug
	case "warn", "warning":
		return slog.LevelWarn
	case "error":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}

func (l *Logger) Request(
	method string,
	path string,
	status int,
	durationMS float64,
) {
	l.Info(
		"http request",
		"method", method,
		"path", path,
		"status", status,
		"duration_ms", durationMS,
	)
}

func (l *Logger) ErrorWithCause(
	message string,
	err error,
) {
	if err == nil {
		l.Error(message)
		return
	}

	l.Error(
		message,
		"error", err.Error(),
	)
}
