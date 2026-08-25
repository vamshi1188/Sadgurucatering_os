package router

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	appErrors "github.com/vamshi1188/Sadgurucatering_os/backend/internal/errors"
)

func TestHealthRoute(t *testing.T) {
	handler := New()

	req := httptest.NewRequest(
		http.MethodGet,
		"/api/v1/health",
		nil,
	)

	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf(
			"expected status %d, got %d",
			http.StatusOK,
			rec.Code,
		)
	}

	if rec.Header().Get("Content-Type") != "application/json" {
		t.Fatal("expected application/json content type")
	}
}

func TestUnknownAPIRouteReturnsJSONNotFound(t *testing.T) {
	handler := New()

	req := httptest.NewRequest(
		http.MethodGet,
		"/api/v1/does-not-exist",
		nil,
	)

	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf(
			"expected status %d, got %d",
			http.StatusNotFound,
			rec.Code,
		)
	}

	if rec.Header().Get("Content-Type") != "application/json" {
		t.Fatal("expected application/json content type")
	}

	var body struct {
		Error struct {
			Code    string `json:"code"`
			Message string `json:"message"`
		} `json:"error"`
	}

	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf(
			"failed to decode JSON response: %v",
			err,
		)
	}

	if body.Error.Code != appErrors.CodeNotFound {
		t.Fatalf(
			"expected error code %q, got %q",
			appErrors.CodeNotFound,
			body.Error.Code,
		)
	}

	if body.Error.Message != "Resource not found" {
		t.Fatalf(
			"expected error message %q, got %q",
			"Resource not found",
			body.Error.Message,
		)
	}
}

func TestUnknownNonAPIRouteReturnsStandardNotFound(t *testing.T) {
	handler := New()

	req := httptest.NewRequest(
		http.MethodGet,
		"/unknown",
		nil,
	)

	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf(
			"expected status %d, got %d",
			http.StatusNotFound,
			rec.Code,
		)
	}
}

func TestUnsupportedMethodReturnsJSONNotFound(t *testing.T) {
	handler := New()

	req := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/health",
		nil,
	)

	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf(
			"expected status %d, got %d",
			http.StatusNotFound,
			rec.Code,
		)
	}

	if rec.Header().Get("Content-Type") != "application/json" {
		t.Fatal("expected application/json content type")
	}
}
