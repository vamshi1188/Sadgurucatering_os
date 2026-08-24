package health

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestNewResponse(t *testing.T) {
	response := NewResponse()

	if response.Status != "ok" {
		t.Fatalf(
			"expected status %q, got %q",
			"ok",
			response.Status,
		)
	}
}

func TestHandler(t *testing.T) {
	request := httptest.NewRequest(
		http.MethodGet,
		"/health",
		nil,
	)

	recorder := httptest.NewRecorder()

	Handler(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf(
			"expected status %d, got %d",
			http.StatusOK,
			recorder.Code,
		)
	}

	if recorder.Header().Get("Content-Type") != "application/json" {
		t.Fatalf("expected application/json content type")
	}

	var response Response

	if err := json.Unmarshal(
		recorder.Body.Bytes(),
		&response,
	); err != nil {
		t.Fatalf(
			"failed to decode health response: %v",
			err,
		)
	}

	if response.Status != "ok" {
		t.Fatalf(
			"expected status %q, got %q",
			"ok",
			response.Status,
		)
	}
}
