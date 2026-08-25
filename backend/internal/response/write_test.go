package response

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestWrite(t *testing.T) {
	recorder := httptest.NewRecorder()

	Write(
		recorder,
		http.StatusOK,
		map[string]any{
			"status": "ok",
		},
		"req_test_123",
	)

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

	var body Response

	if err := json.Unmarshal(
		recorder.Body.Bytes(),
		&body,
	); err != nil {
		t.Fatalf(
			"failed to decode response: %v",
			err,
		)
	}

	if body.Meta == nil {
		t.Fatal("expected response metadata")
	}

	if body.Meta.RequestID != "req_test_123" {
		t.Fatalf(
			"expected request ID %q, got %q",
			"req_test_123",
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

func TestWriteWithMeta(t *testing.T) {
	recorder := httptest.NewRecorder()

	meta := Meta{
		RequestID: "req_test_456",
	}

	WriteWithMeta(
		recorder,
		http.StatusCreated,
		map[string]string{
			"id": "cus_123",
		},
		meta,
	)

	if recorder.Code != http.StatusCreated {
		t.Fatalf(
			"expected status %d, got %d",
			http.StatusCreated,
			recorder.Code,
		)
	}

	var body Response

	if err := json.Unmarshal(
		recorder.Body.Bytes(),
		&body,
	); err != nil {
		t.Fatalf(
			"failed to decode response: %v",
			err,
		)
	}

	if body.Meta == nil {
		t.Fatal("expected response metadata")
	}

	if body.Meta.RequestID != "req_test_456" {
		t.Fatalf(
			"expected request ID %q, got %q",
			"req_test_456",
			body.Meta.RequestID,
		)
	}
}
