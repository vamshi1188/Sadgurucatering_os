package health

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/response"
)

func TestNewResponse(t *testing.T) {
	result := NewResponse()

	if result.Status != "ok" {
		t.Fatalf(
			"expected status %q, got %q",
			"ok",
			result.Status,
		)
	}
}

func TestHandler(t *testing.T) {
	request := httptest.NewRequest(
		http.MethodGet,
		"/health",
		nil,
	)

	request.Header.Set(
		"X-Request-ID",
		"req_health_test",
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
		t.Fatal("expected application/json content type")
	}

	var body response.Response

	if err := json.Unmarshal(
		recorder.Body.Bytes(),
		&body,
	); err != nil {
		t.Fatalf(
			"failed to decode API response: %v",
			err,
		)
	}

	if body.Meta == nil {
		t.Fatal("expected response metadata")
	}

	if body.Meta.RequestID != "req_health_test" {
		t.Fatalf(
			"expected request ID %q, got %q",
			"req_health_test",
			body.Meta.RequestID,
		)
	}

	data, ok := body.Data.(map[string]any)
	if !ok {
		t.Fatalf("expected response data object")
	}

	if data["status"] != "ok" {
		t.Fatalf(
			"expected status %q, got %v",
			"ok",
			data["status"],
		)
	}
}
