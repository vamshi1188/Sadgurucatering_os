package router

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestUnknownAPIRouteReturnsNotFound(t *testing.T) {
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
}

func TestUnknownRouteReturnsNotFound(t *testing.T) {
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
