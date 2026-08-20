package response

import (
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	appErrors "github.com/vamshi1188/Sadgurucatering_os/backend/internal/errors"
)

func TestSuccess(t *testing.T) {
	data := map[string]any{
		"id":   "cus_123",
		"name": "Ramesh",
	}

	resp := Success(data)

	if resp.Data == nil {
		t.Fatal("expected response data")
	}
}

func TestSuccessJSON(t *testing.T) {
	data := map[string]any{
		"id":   "cus_123",
		"name": "Ramesh",
	}

	resp := Success(data)

	body, err := json.Marshal(resp)
	if err != nil {
		t.Fatalf("failed to marshal response: %v", err)
	}

	expected := `{"data":{"id":"cus_123","name":"Ramesh"}}`

	if string(body) != expected {
		t.Fatalf(
			"unexpected JSON response: got %s, want %s",
			body,
			expected,
		)
	}
}

func TestSuccessEmptySlice(t *testing.T) {
	resp := Success([]string{})

	body, err := json.Marshal(resp)
	if err != nil {
		t.Fatalf("failed to marshal response: %v", err)
	}

	expected := `{"data":[]}`

	if string(body) != expected {
		t.Fatalf(
			"unexpected response: got %s, want %s",
			body,
			expected,
		)
	}
}

func TestFailure(t *testing.T) {
	resp := Failure(
		"CUSTOMER_NOT_FOUND",
		"Customer not found",
	)

	if resp.Error.Code != "CUSTOMER_NOT_FOUND" {
		t.Fatalf("unexpected code: %s", resp.Error.Code)
	}

	if resp.Error.Message != "Customer not found" {
		t.Fatalf("unexpected message: %s", resp.Error.Message)
	}
}

func TestWriteErrorNotFound(t *testing.T) {
	recorder := httptest.NewRecorder()

	err := appErrors.NotFoundError("Customer not found")

	WriteError(recorder, err)

	if recorder.Code != http.StatusNotFound {
		t.Fatalf(
			"expected status %d, got %d",
			http.StatusNotFound,
			recorder.Code,
		)
	}

	if recorder.Header().Get("Content-Type") != "application/json" {
		t.Fatalf("expected JSON content type")
	}

	var body ErrorResponse

	if err := json.Unmarshal(recorder.Body.Bytes(), &body); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if body.Error.Code != appErrors.CodeNotFound {
		t.Fatalf("unexpected error code: %s", body.Error.Code)
	}

	if body.Error.Message != "Customer not found" {
		t.Fatalf("unexpected error message: %s", body.Error.Message)
	}
}

func TestWriteErrorUnknownError(t *testing.T) {
	recorder := httptest.NewRecorder()

	err := errors.New("postgres password=secret123")

	WriteError(recorder, err)

	if recorder.Code != http.StatusInternalServerError {
		t.Fatalf(
			"expected status %d, got %d",
			http.StatusInternalServerError,
			recorder.Code,
		)
	}

	var body ErrorResponse

	if err := json.Unmarshal(recorder.Body.Bytes(), &body); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if body.Error.Code != appErrors.CodeInternal {
		t.Fatalf(
			"unexpected error code: %s",
			body.Error.Code,
		)
	}

	if body.Error.Message != "An unexpected error occurred" {
		t.Fatalf(
			"unexpected error message: %s",
			body.Error.Message,
		)
	}

	if body.Error.Message == "postgres password=secret123" {
		t.Fatal("internal error details leaked into public response")
	}
}
