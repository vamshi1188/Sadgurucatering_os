package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/logger"
)

func TestChain(t *testing.T) {
	var order []string

	first := func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			order = append(order, "first")
			next.ServeHTTP(w, r)
		})
	}

	second := func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			order = append(order, "second")
			next.ServeHTTP(w, r)
		})
	}

	handler := Chain(
		http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			order = append(order, "handler")
		}),
		first,
		second,
	)

	request := httptest.NewRequest(
		http.MethodGet,
		"/test",
		nil,
	)

	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	expected := []string{
		"first",
		"second",
		"handler",
	}

	if len(order) != len(expected) {
		t.Fatalf(
			"unexpected order length: got %d, want %d",
			len(order),
			len(expected),
		)
	}

	for i := range expected {
		if order[i] != expected[i] {
			t.Fatalf(
				"unexpected middleware order: got %v, want %v",
				order,
				expected,
			)
		}
	}
}

func TestRequestID(t *testing.T) {
	handler := RequestID(
		http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			requestID := r.Header.Get(RequestIDHeader)

			if requestID == "" {
				t.Fatal("request ID was not available")
			}
		}),
	)

	request := httptest.NewRequest(
		http.MethodGet,
		"/test",
		nil,
	)

	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	requestID := recorder.Header().Get(RequestIDHeader)

	if requestID == "" {
		t.Fatal("expected X-Request-ID response header")
	}

	if len(requestID) <= len("req_") {
		t.Fatalf("unexpected request ID: %s", requestID)
	}
}

func TestRequestIDPreservesExistingID(t *testing.T) {
	handler := RequestID(
		http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {}),
	)

	request := httptest.NewRequest(
		http.MethodGet,
		"/test",
		nil,
	)

	request.Header.Set(
		RequestIDHeader,
		"req_existing",
	)

	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	if recorder.Header().Get(RequestIDHeader) != "req_existing" {
		t.Fatal("existing request ID was not preserved")
	}
}

func TestSecurityHeaders(t *testing.T) {
	handler := SecurityHeaders(
		http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusOK)
		}),
	)

	request := httptest.NewRequest(
		http.MethodGet,
		"/test",
		nil,
	)

	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	if recorder.Header().Get("X-Content-Type-Options") != "nosniff" {
		t.Fatal("missing X-Content-Type-Options")
	}

	if recorder.Header().Get("X-Frame-Options") != "DENY" {
		t.Fatal("missing X-Frame-Options")
	}

	if recorder.Header().Get("Referrer-Policy") != "strict-origin-when-cross-origin" {
		t.Fatal("missing Referrer-Policy")
	}
}

func TestRecovery(t *testing.T) {
	handler := Recovery(
		http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			panic("test panic")
		}),
	)

	request := httptest.NewRequest(
		http.MethodGet,
		"/test",
		nil,
	)

	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusInternalServerError {
		t.Fatalf(
			"expected status %d, got %d",
			http.StatusInternalServerError,
			recorder.Code,
		)
	}
}

func TestRequestLogger(t *testing.T) {
	var logOutput testLogWriter

	log := logger.New(&logOutput, "info")

	handler := RequestLogger(log)(
		http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusCreated)
		}),
	)

	request := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/test",
		nil,
	)

	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusCreated {
		t.Fatalf(
			"expected status %d, got %d",
			http.StatusCreated,
			recorder.Code,
		)
	}

	if len(logOutput.data) == 0 {
		t.Fatal("expected request log output")
	}
}

type testLogWriter struct {
	data []byte
}

func (w *testLogWriter) Write(p []byte) (int, error) {
	w.data = append(w.data, p...)

	return len(p), nil
}
