package errors

import (
	"errors"
	"net/http"
	"testing"
)

func TestNew(t *testing.T) {
	err := New(
		CodeNotFound,
		"Customer not found",
		http.StatusNotFound,
	)

	if err.Code != CodeNotFound {
		t.Fatalf("expected code %q, got %q", CodeNotFound, err.Code)
	}

	if err.Message != "Customer not found" {
		t.Fatalf("unexpected message: %s", err.Message)
	}

	if err.Status != http.StatusNotFound {
		t.Fatalf(
			"expected status %d, got %d",
			http.StatusNotFound,
			err.Status,
		)
	}

	if err.Err != nil {
		t.Fatal("expected underlying error to be nil")
	}
}

func TestWrap(t *testing.T) {
	cause := errors.New("database connection failed")

	err := Wrap(
		cause,
		CodeInternal,
		"An unexpected error occurred",
		http.StatusInternalServerError,
	)

	if err.Code != CodeInternal {
		t.Fatalf("unexpected code: %s", err.Code)
	}

	if err.Status != http.StatusInternalServerError {
		t.Fatalf("unexpected status: %d", err.Status)
	}

	if err.Err != cause {
		t.Fatal("expected original error to be preserved")
	}
}

func TestUnwrap(t *testing.T) {
	cause := errors.New("database connection failed")

	err := Wrap(
		cause,
		CodeInternal,
		"An unexpected error occurred",
		http.StatusInternalServerError,
	)

	if !errors.Is(err, cause) {
		t.Fatal("expected wrapped error to contain original cause")
	}
}

func TestErrorMessageWithCause(t *testing.T) {
	cause := errors.New("database connection failed")

	err := Wrap(
		cause,
		CodeInternal,
		"An unexpected error occurred",
		http.StatusInternalServerError,
	)

	expected := "An unexpected error occurred: database connection failed"

	if err.Error() != expected {
		t.Fatalf(
			"unexpected error string: got %q, want %q",
			err.Error(),
			expected,
		)
	}
}
