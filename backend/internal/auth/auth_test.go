package auth

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func newTestHandler() *Handler {
	return New(Config{
		Password: "test-password",
		Secret:   "test-session-secret",
		Secure:   false,
	})
}

func TestLoginRejectsWrongPassword(t *testing.T) {
	handler := newTestHandler()

	req := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/auth/login",
		strings.NewReader(`{"password":"wrong-password"}`),
	)

	req.Header.Set("Content-Type", "application/json")

	recorder := httptest.NewRecorder()

	handler.Login(recorder, req)

	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf(
			"expected status %d, got %d",
			http.StatusUnauthorized,
			recorder.Code,
		)
	}
}

func TestLoginCreatesSession(t *testing.T) {
	handler := newTestHandler()

	req := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/auth/login",
		strings.NewReader(`{"password":"test-password"}`),
	)

	req.Header.Set("Content-Type", "application/json")

	recorder := httptest.NewRecorder()

	handler.Login(recorder, req)

	if recorder.Code != http.StatusOK {
		t.Fatalf(
			"expected status %d, got %d",
			http.StatusOK,
			recorder.Code,
		)
	}

	cookie := recorder.Result().Cookies()

	if len(cookie) != 1 {
		t.Fatalf("expected one cookie, got %d", len(cookie))
	}

	if cookie[0].Name != CookieName {
		t.Fatalf(
			"expected cookie %q, got %q",
			CookieName,
			cookie[0].Name,
		)
	}

	if !cookie[0].HttpOnly {
		t.Fatal("expected authentication cookie to be HttpOnly")
	}
}

func TestSessionRequiresAuthentication(t *testing.T) {
	handler := newTestHandler()

	req := httptest.NewRequest(
		http.MethodGet,
		"/api/v1/auth/session",
		nil,
	)

	recorder := httptest.NewRecorder()

	handler.Session(recorder, req)

	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf(
			"expected status %d, got %d",
			http.StatusUnauthorized,
			recorder.Code,
		)
	}
}

func TestSessionAcceptsValidCookie(t *testing.T) {
	handler := newTestHandler()

	loginRequest := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/auth/login",
		strings.NewReader(`{"password":"test-password"}`),
	)

	loginRequest.Header.Set("Content-Type", "application/json")

	loginRecorder := httptest.NewRecorder()

	handler.Login(loginRecorder, loginRequest)

	cookies := loginRecorder.Result().Cookies()

	if len(cookies) != 1 {
		t.Fatalf("expected one cookie, got %d", len(cookies))
	}

	sessionRequest := httptest.NewRequest(
		http.MethodGet,
		"/api/v1/auth/session",
		nil,
	)

	sessionRequest.AddCookie(cookies[0])

	sessionRecorder := httptest.NewRecorder()

	handler.Session(sessionRecorder, sessionRequest)

	if sessionRecorder.Code != http.StatusOK {
		t.Fatalf(
			"expected status %d, got %d",
			http.StatusOK,
			sessionRecorder.Code,
		)
	}
}

func TestLogoutClearsSessionCookie(t *testing.T) {
	handler := newTestHandler()

	req := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/auth/logout",
		nil,
	)

	recorder := httptest.NewRecorder()

	handler.Logout(recorder, req)

	if recorder.Code != http.StatusOK {
		t.Fatalf(
			"expected status %d, got %d",
			http.StatusOK,
			recorder.Code,
		)
	}

	cookies := recorder.Result().Cookies()

	if len(cookies) != 1 {
		t.Fatalf("expected one cookie, got %d", len(cookies))
	}

	if cookies[0].MaxAge >= 0 {
		t.Fatalf("expected cookie deletion, got MaxAge=%d", cookies[0].MaxAge)
	}
}
