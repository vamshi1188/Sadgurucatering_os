package router

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/auth"

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

func TestAuthLoginRoute(t *testing.T) {
	authHandler := auth.New(auth.Config{
		Password: "test-password",
		Secret:   "test-session-secret",
		Secure:   false,
	})

	handler := New(authHandler)

	req := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/auth/login",
		strings.NewReader(`{"password":"test-password"}`),
	)

	req.Header.Set("Content-Type", "application/json")

	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf(
			"expected status %d, got %d",
			http.StatusOK,
			rec.Code,
		)
	}

	cookies := rec.Result().Cookies()

	if len(cookies) != 1 {
		t.Fatalf(
			"expected one session cookie, got %d",
			len(cookies),
		)
	}

	if cookies[0].Name != auth.CookieName {
		t.Fatalf(
			"expected cookie %q, got %q",
			auth.CookieName,
			cookies[0].Name,
		)
	}
}

func TestAuthSessionRouteRequiresCookie(t *testing.T) {
	authHandler := auth.New(auth.Config{
		Password: "test-password",
		Secret:   "test-session-secret",
		Secure:   false,
	})

	handler := New(authHandler)

	req := httptest.NewRequest(
		http.MethodGet,
		"/api/v1/auth/session",
		nil,
	)

	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Fatalf(
			"expected status %d, got %d",
			http.StatusUnauthorized,
			rec.Code,
		)
	}
}

func TestAuthSessionRouteAcceptsLoginCookie(t *testing.T) {
	authHandler := auth.New(auth.Config{
		Password: "test-password",
		Secret:   "test-session-secret",
		Secure:   false,
	})

	handler := New(authHandler)

	loginReq := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/auth/login",
		strings.NewReader(`{"password":"test-password"}`),
	)

	loginReq.Header.Set("Content-Type", "application/json")

	loginRec := httptest.NewRecorder()

	handler.ServeHTTP(loginRec, loginReq)

	cookies := loginRec.Result().Cookies()

	if len(cookies) != 1 {
		t.Fatalf(
			"expected one session cookie, got %d",
			len(cookies),
		)
	}

	sessionReq := httptest.NewRequest(
		http.MethodGet,
		"/api/v1/auth/session",
		nil,
	)

	sessionReq.AddCookie(cookies[0])

	sessionRec := httptest.NewRecorder()

	handler.ServeHTTP(sessionRec, sessionReq)

	if sessionRec.Code != http.StatusOK {
		t.Fatalf(
			"expected status %d, got %d",
			http.StatusOK,
			sessionRec.Code,
		)
	}
}

func TestAuthLogoutRoute(t *testing.T) {
	authHandler := auth.New(auth.Config{
		Password: "test-password",
		Secret:   "test-session-secret",
		Secure:   false,
	})

	handler := New(authHandler)

	req := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/auth/logout",
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

	cookies := rec.Result().Cookies()

	if len(cookies) != 1 {
		t.Fatalf(
			"expected one cookie, got %d",
			len(cookies),
		)
	}

	if cookies[0].MaxAge >= 0 {
		t.Fatalf(
			"expected session cookie deletion, got MaxAge=%d",
			cookies[0].MaxAge,
		)
	}
}
