package router

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/auth"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/events"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/finance"
	"golang.org/x/crypto/bcrypt"

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
	authHandler, _ := newRouterAuthHandler(t, "owner")

	handler := New(authHandler)

	req := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/auth/login",
		strings.NewReader(`{"username":"owner","password":"test-password"}`),
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

	if len(rec.Result().Cookies()) != 0 {
		t.Fatal("login must not set a session cookie")
	}
	var body struct {
		Data struct {
			Token string `json:"token"`
		} `json:"data"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil || body.Data.Token == "" {
		t.Fatalf("login did not return bearer token: %s", rec.Body)
	}
}

func TestAuthSessionRouteRequiresBearerToken(t *testing.T) {
	authHandler, _ := newRouterAuthHandler(t, "owner")

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

func TestAuthSessionRouteRejectsLegacySessionCookie(t *testing.T) {
	authHandler, _ := newRouterAuthHandler(t, "owner")
	handler := New(authHandler)
	request := httptest.NewRequest(http.MethodGet, "/api/v1/auth/session", nil)
	request.AddCookie(&http.Cookie{Name: "sadguru_session", Value: "legacy-token"})
	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf("legacy cookie authenticated session: %d", recorder.Code)
	}
}

func TestAuthSessionRouteAcceptsBearerToken(t *testing.T) {
	authHandler, _ := newRouterAuthHandler(t, "owner")

	handler := New(authHandler)

	loginReq := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/auth/login",
		strings.NewReader(`{"username":"owner","password":"test-password"}`),
	)

	loginReq.Header.Set("Content-Type", "application/json")

	loginRec := httptest.NewRecorder()

	handler.ServeHTTP(loginRec, loginReq)

	var body struct {
		Data struct {
			Token string `json:"token"`
		} `json:"data"`
	}
	if err := json.Unmarshal(loginRec.Body.Bytes(), &body); err != nil || body.Data.Token == "" {
		t.Fatalf("login did not return bearer token: %s", loginRec.Body)
	}

	sessionReq := httptest.NewRequest(
		http.MethodGet,
		"/api/v1/auth/session",
		nil,
	)

	sessionReq.Header.Set("Authorization", "Bearer "+body.Data.Token)

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
	authHandler, _ := newRouterAuthHandler(t, "owner")

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

	if len(rec.Result().Cookies()) != 0 {
		t.Fatal("bearer logout unexpectedly emitted cookies")
	}
}

func TestLogoutEndpointInvalidatesSession(t *testing.T) {
	authHandler, _ := newRouterAuthHandler(t, "owner")
	handler := New(authHandler)

	login := httptest.NewRecorder()
	handler.ServeHTTP(login, httptest.NewRequest(
		http.MethodPost,
		"/api/v1/auth/login",
		strings.NewReader(`{"username":"owner","password":"test-password"}`),
	))
	var loginBody struct {
		Data struct {
			Token string `json:"token"`
		} `json:"data"`
	}
	if err := json.Unmarshal(login.Body.Bytes(), &loginBody); err != nil || loginBody.Data.Token == "" {
		t.Fatalf("login did not return bearer token: %s", login.Body)
	}

	logoutRequest := httptest.NewRequest(http.MethodPost, "/api/v1/auth/logout", nil)
	logoutRequest.Header.Set("Authorization", "Bearer "+loginBody.Data.Token)
	logout := httptest.NewRecorder()
	handler.ServeHTTP(logout, logoutRequest)
	if logout.Code != http.StatusOK {
		t.Fatalf("logout returned %d: %s", logout.Code, logout.Body)
	}

	sessionRequest := httptest.NewRequest(http.MethodGet, "/api/v1/auth/session", nil)
	sessionRequest.Header.Set("Authorization", "Bearer "+loginBody.Data.Token)
	session := httptest.NewRecorder()
	handler.ServeHTTP(session, sessionRequest)
	if session.Code != http.StatusUnauthorized {
		t.Fatalf("revoked session returned %d, want 401", session.Code)
	}
}

func TestAuthenticationAndUserManagementRoutesRequireAuthentication(t *testing.T) {
	authHandler, _ := newRouterAuthHandler(t, "owner")
	handler := New(authHandler)

	tests := []struct {
		method string
		path   string
		body   string
	}{
		{http.MethodGet, "/api/v1/auth/session", ""},
		{http.MethodPost, "/api/v1/auth/change-password", `{}`},
		{http.MethodGet, "/api/v1/users", ""},
		{http.MethodPost, "/api/v1/users", `{}`},
		{http.MethodPatch, "/api/v1/users/2", `{"role":"supervisor"}`},
		{http.MethodDelete, "/api/v1/users/2", ""},
		{http.MethodPost, "/api/v1/users/2/reset-password", `{"password":"long-enough-password"}`},
	}

	for _, test := range tests {
		t.Run(test.method+" "+test.path, func(t *testing.T) {
			request := httptest.NewRequest(test.method, test.path, strings.NewReader(test.body))
			recorder := httptest.NewRecorder()

			handler.ServeHTTP(recorder, request)

			if recorder.Code != http.StatusUnauthorized {
				t.Fatalf("expected unauthenticated route to return 401, got %d: %s", recorder.Code, recorder.Body)
			}
		})
	}
}

func TestOwnerCanAccessEveryUserManagementRoute(t *testing.T) {
	authHandler, _ := newRouterAuthHandler(t, "owner")
	handler := New(authHandler)

	login := httptest.NewRecorder()
	handler.ServeHTTP(login, httptest.NewRequest(
		http.MethodPost,
		"/api/v1/auth/login",
		strings.NewReader(`{"username":"owner","password":"test-password"}`),
	))
	var loginBody struct {
		Data struct {
			Token string `json:"token"`
		} `json:"data"`
	}
	if err := json.Unmarshal(login.Body.Bytes(), &loginBody); err != nil || loginBody.Data.Token == "" {
		t.Fatalf("owner login did not return bearer token: %s", login.Body)
	}

	tests := []struct {
		method string
		path   string
		body   string
		status int
	}{
		{http.MethodPost, "/api/v1/auth/change-password", `{"current_password":"test-password","new_password":"a-stronger-test-password"}`, http.StatusOK},
		{http.MethodGet, "/api/v1/users", "", http.StatusOK},
		{http.MethodPost, "/api/v1/users", `{"username":"supervisor","role":"supervisor","password":"initial-password"}`, http.StatusCreated},
		{http.MethodPatch, "/api/v1/users/2", `{"role":"supervisor"}`, http.StatusOK},
		{http.MethodDelete, "/api/v1/users/2", "", http.StatusNoContent},
		{http.MethodPost, "/api/v1/users/2/reset-password", `{"password":"long-enough-password"}`, http.StatusOK},
	}

	for _, test := range tests {
		t.Run(test.method+" "+test.path, func(t *testing.T) {
			request := httptest.NewRequest(test.method, test.path, strings.NewReader(test.body))
			request.Header.Set("Authorization", "Bearer "+loginBody.Data.Token)
			recorder := httptest.NewRecorder()

			handler.ServeHTTP(recorder, request)

			if recorder.Code != test.status {
				t.Fatalf("expected owner route to return %d, got %d: %s", test.status, recorder.Code, recorder.Body)
			}
		})
	}
}

func TestEventsUpdateStatusDynamicPatchRoute(t *testing.T) {
	authHandler, _ := newRouterAuthHandler(t, "owner")

	eventsHandler := events.NewHandler(nil)
	handler := NewWithEvents(authHandler, eventsHandler)

	req := httptest.NewRequest(
		http.MethodPatch,
		"/api/v1/events/123/status",
		strings.NewReader(`{"status":"running"}`),
	)

	req.Header.Set("Content-Type", "application/json")

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

func TestDeleteRoutesRequireAuthentication(t *testing.T) {
	authHandler, _ := newRouterAuthHandler(t, "owner")

	eventsHandler := events.NewHandler(nil)
	financeHandler := finance.NewHandler(nil)
	handler := NewWithFinance(authHandler, eventsHandler, financeHandler)

	tests := []string{
		"/api/v1/events/123",
		"/api/v1/events/123/expenses/456",
	}
	for _, path := range tests {
		t.Run(path, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodDelete, path, nil)
			rec := httptest.NewRecorder()

			handler.ServeHTTP(rec, req)

			if rec.Code != http.StatusUnauthorized {
				t.Fatalf("expected status %d, got %d", http.StatusUnauthorized, rec.Code)
			}
		})
	}
}

func TestSupervisorCannotWriteThroughBusinessOrUserRoutes(t *testing.T) {
	authHandler, _ := newRouterAuthHandler(t, "supervisor")
	eventsHandler := events.NewHandler(nil)
	financeHandler := finance.NewHandler(nil)
	handler := NewWithFinance(authHandler, eventsHandler, financeHandler)

	login := httptest.NewRecorder()
	handler.ServeHTTP(login, httptest.NewRequest(
		http.MethodPost,
		"/api/v1/auth/login",
		strings.NewReader(`{"username":"owner","password":"test-password"}`),
	))
	var loginBody struct {
		Data struct {
			Token string `json:"token"`
		} `json:"data"`
	}
	if err := json.Unmarshal(login.Body.Bytes(), &loginBody); err != nil || loginBody.Data.Token == "" {
		t.Fatalf("supervisor login did not return bearer token: %s", login.Body)
	}

	tests := []struct {
		method string
		path   string
		body   string
	}{
		{http.MethodGet, "/api/v1/users", ""},
		{http.MethodPost, "/api/v1/events", `{}`},
		{http.MethodPatch, "/api/v1/events/123/status", `{"status":"running"}`},
		{http.MethodDelete, "/api/v1/events/123", ""},
		{http.MethodPost, "/api/v1/events/123/income", `{}`},
		{http.MethodDelete, "/api/v1/events/123/income/456", ""},
		{http.MethodPost, "/api/v1/events/123/expenses", `{}`},
		{http.MethodDelete, "/api/v1/events/123/expenses/456", ""},
		{http.MethodPost, "/api/v1/users", `{}`},
		{http.MethodPatch, "/api/v1/users/2", `{"role":"owner"}`},
		{http.MethodDelete, "/api/v1/users/2", ""},
		{http.MethodPost, "/api/v1/users/2/reset-password", `{"password":"long-enough-password"}`},
	}
	for _, test := range tests {
		t.Run(test.method+" "+test.path, func(t *testing.T) {
			request := httptest.NewRequest(test.method, test.path, strings.NewReader(test.body))
			request.Header.Set("Authorization", "Bearer "+loginBody.Data.Token)
			recorder := httptest.NewRecorder()

			handler.ServeHTTP(recorder, request)

			if recorder.Code != http.StatusForbidden {
				t.Fatalf("expected supervisor write to be forbidden, got %d: %s", recorder.Code, recorder.Body)
			}
		})
	}
}

type routerTestRepo struct {
	user      auth.User
	tokenHash []byte
	revoked   bool
}

func newRouterAuthHandler(t *testing.T, role string) (*auth.Handler, *routerTestRepo) {
	t.Helper()
	hash, err := bcrypt.GenerateFromPassword([]byte("test-password"), bcrypt.MinCost)
	if err != nil {
		t.Fatal(err)
	}
	repo := &routerTestRepo{user: auth.User{
		ID: 1, Username: "owner", Role: role, Active: true, PasswordHash: string(hash),
	}}
	return auth.New(repo), repo
}

func (repo *routerTestRepo) BootstrapOwner(context.Context, string, string) error {
	return nil
}
func (repo *routerTestRepo) UserByUsername(_ context.Context, username string) (auth.User, error) {
	if strings.EqualFold(username, repo.user.Username) {
		return repo.user, nil
	}
	return auth.User{}, auth.ErrNotFound
}
func (repo *routerTestRepo) CreateSession(_ context.Context, _ int64, tokenHash []byte, _ time.Time, _ string) error {
	repo.tokenHash = append([]byte(nil), tokenHash...)
	return nil
}
func (repo *routerTestRepo) UserForSession(_ context.Context, tokenHash []byte) (auth.User, error) {
	if repo.revoked || string(repo.tokenHash) != string(tokenHash) {
		return auth.User{}, auth.ErrNotFound
	}
	return repo.user, nil
}
func (repo *routerTestRepo) RevokeSession(_ context.Context, tokenHash []byte) error {
	if string(repo.tokenHash) == string(tokenHash) {
		repo.revoked = true
	}
	return nil
}
func (repo *routerTestRepo) ChangePassword(context.Context, int64, string, []byte) error { return nil }
func (repo *routerTestRepo) ListUsers(context.Context) ([]auth.User, error)              { return nil, nil }
func (repo *routerTestRepo) CreateUser(context.Context, string, string, string, int64) (auth.User, error) {
	return auth.User{}, nil
}
func (repo *routerTestRepo) UpdateUser(context.Context, int64, *string, *string, *bool, int64) (auth.User, error) {
	return repo.user, nil
}
func (repo *routerTestRepo) DeleteUser(context.Context, int64, int64) error            { return nil }
func (repo *routerTestRepo) ResetPassword(context.Context, int64, string, int64) error { return nil }
