package logger

import (
	"bytes"
	"encoding/json"
	"errors"
	"testing"
)

func TestLoggerProducesJSON(t *testing.T) {
	var buffer bytes.Buffer

	log := New(&buffer, "info")

	log.Info("application started")

	var entry map[string]any

	if err := json.Unmarshal(buffer.Bytes(), &entry); err != nil {
		t.Fatalf("expected valid JSON log: %v", err)
	}

	if entry["msg"] != "application started" {
		t.Fatalf("unexpected message: %v", entry["msg"])
	}

	if entry["level"] != "INFO" {
		t.Fatalf("unexpected level: %v", entry["level"])
	}
}

func TestLoggerLevel(t *testing.T) {
	var buffer bytes.Buffer

	log := New(&buffer, "error")

	log.Info("this should not appear")

	if buffer.Len() != 0 {
		t.Fatal("expected INFO log to be filtered at ERROR level")
	}

	log.Error("this should appear")

	if buffer.Len() == 0 {
		t.Fatal("expected ERROR log to be written")
	}
}

func TestErrorWithCause(t *testing.T) {
	var buffer bytes.Buffer

	log := New(&buffer, "error")

	log.ErrorWithCause(
		"database operation failed",
		errors.New("connection refused"),
	)

	var entry map[string]any

	if err := json.Unmarshal(buffer.Bytes(), &entry); err != nil {
		t.Fatalf("expected valid JSON log: %v", err)
	}

	if entry["msg"] != "database operation failed" {
		t.Fatalf("unexpected message: %v", entry["msg"])
	}

	if entry["error"] != "connection refused" {
		t.Fatalf("unexpected error: %v", entry["error"])
	}
}

func TestRequestLogging(t *testing.T) {
	var buffer bytes.Buffer

	log := New(&buffer, "info")

	log.Request(
		"GET",
		"/api/v1/customers",
		200,
		12.5,
	)

	var entry map[string]any

	if err := json.Unmarshal(buffer.Bytes(), &entry); err != nil {
		t.Fatalf("expected valid JSON log: %v", err)
	}

	if entry["msg"] != "http request" {
		t.Fatalf("unexpected message: %v", entry["msg"])
	}

	if entry["method"] != "GET" {
		t.Fatalf("unexpected method: %v", entry["method"])
	}

	if entry["path"] != "/api/v1/customers" {
		t.Fatalf("unexpected path: %v", entry["path"])
	}

	if entry["status"] != float64(200) {
		t.Fatalf("unexpected status: %v", entry["status"])
	}
}
