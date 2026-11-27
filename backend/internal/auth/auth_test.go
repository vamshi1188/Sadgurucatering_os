package auth

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"golang.org/x/crypto/bcrypt"
)

type memoryRepository struct {
	user         User
	tokenHash    []byte
	revoked      bool
	created      bool
	reset        bool
	updated      bool
	updateActive *bool
	deleted      bool
	users        []User
}

func newMemoryRepository(role string) *memoryRepository {
	hash, _ := bcrypt.GenerateFromPassword([]byte("initial-password"), bcrypt.MinCost)
	return &memoryRepository{
		user: User{
			ID: 1, Username: "owner", Role: role, Active: true,
			MustChangePassword: true, PasswordHash: string(hash),
		},
	}
}

func (repo *memoryRepository) BootstrapOwner(context.Context, string, string) error {
	return nil
}
func (repo *memoryRepository) UserByUsername(_ context.Context, username string) (User, error) {
	if strings.EqualFold(username, repo.user.Username) {
		return repo.user, nil
	}
	return User{}, ErrNotFound
}
func (repo *memoryRepository) CreateSession(_ context.Context, _ int64, tokenHash []byte, _ time.Time, _ string) error {
	repo.tokenHash = append([]byte(nil), tokenHash...)
	return nil
}
func (repo *memoryRepository) UserForSession(_ context.Context, tokenHash []byte) (User, error) {
	if repo.revoked || len(repo.tokenHash) == 0 || string(tokenHash) != string(repo.tokenHash) || !repo.user.Active {
		return User{}, ErrNotFound
	}
	return repo.user, nil
}
func (repo *memoryRepository) RevokeSession(_ context.Context, tokenHash []byte) error {
	if string(repo.tokenHash) == string(tokenHash) {
		repo.revoked = true
	}
	return nil
}
func (repo *memoryRepository) ChangePassword(_ context.Context, _ int64, hash string, _ []byte) error {
	repo.user.PasswordHash = hash
	repo.user.MustChangePassword = false
	return nil
}
func (repo *memoryRepository) ListUsers(context.Context) ([]User, error) { return repo.users, nil }
func (repo *memoryRepository) CreateUser(_ context.Context, username, role, hash string, _ int64) (User, error) {
	repo.created = true
	return User{ID: 2, Username: username, Role: role, Active: true, MustChangePassword: true, PasswordHash: hash}, nil
}
func (repo *memoryRepository) UpdateUser(_ context.Context, _ int64, _ *string, _ *string, active *bool, _ int64) (User, error) {
	repo.updated = true
	repo.updateActive = active
	if active != nil {
		repo.user.Active = *active
	}
	return repo.user, nil
}
func (repo *memoryRepository) DeleteUser(context.Context, int64, int64) error {
	repo.deleted = true
	return nil
}
func (repo *memoryRepository) ResetPassword(context.Context, int64, string, int64) error {
	repo.reset = true
	return nil
}

func performLogin(t *testing.T, handler *Handler) (loginResponse, *httptest.ResponseRecorder) {
	t.Helper()
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/login",
		strings.NewReader(`{"username":"owner","password":"initial-password"}`))
	recorder := httptest.NewRecorder()
	handler.Login(recorder, req)
	var body struct {
		Data loginResponse `json:"data"`
	}
	_ = json.Unmarshal(recorder.Body.Bytes(), &body)
	return body.Data, recorder
}

func TestLoginReturnsOpaqueBearerTokenWithoutCookie(t *testing.T) {
	repo := newMemoryRepository("owner")
	handler := New(repo)
	body, recorder := performLogin(t, handler)
	if recorder.Code != http.StatusOK {
		t.Fatalf("login returned %d: %s", recorder.Code, recorder.Body)
	}
	if body.Token == "" || body.User.Username != "owner" || !body.User.MustChangePassword {
		t.Fatalf("unexpected login response: %+v", body)
	}
	if cookies := recorder.Result().Cookies(); len(cookies) != 0 {
		t.Fatalf("login must not set cookies; got %d", len(cookies))
	}
	expected := sha256.Sum256([]byte(body.Token))
	if string(expected[:]) != string(repo.tokenHash) {
		t.Fatal("repository did not receive only the token hash")
	}
}

func TestSessionAndRoleMiddlewareUseBearerToken(t *testing.T) {
	repo := newMemoryRepository("owner")
	repo.user.MustChangePassword = false
	handler := New(repo)
	login, recorder := performLogin(t, handler)
	if recorder.Code != http.StatusOK {
		t.Fatal("login failed")
	}
	req := httptest.NewRequest(http.MethodGet, "/api/v1/auth/session", nil)
	req.Header.Set("Authorization", "Bearer "+login.Token)
	session := httptest.NewRecorder()
	handler.Session(session, req)
	if session.Code != http.StatusOK || !strings.Contains(session.Body.String(), `"must_change_password":false`) {
		t.Fatalf("session did not return current user: %d %s", session.Code, session.Body)
	}

	protected := handler.RequireOwner(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	}))
	ownerRequest := httptest.NewRequest(http.MethodPost, "/", nil)
	ownerRequest.Header.Set("Authorization", "Bearer "+login.Token)
	ownerResponse := httptest.NewRecorder()
	protected.ServeHTTP(ownerResponse, ownerRequest)
	if ownerResponse.Code != http.StatusNoContent {
		t.Fatalf("owner access returned %d", ownerResponse.Code)
	}
}

func TestStaffCannotUseOwnerMiddleware(t *testing.T) {
	repo := newMemoryRepository("supervisor")
	repo.user.MustChangePassword = false
	handler := New(repo)
	token, _, err := newToken()
	if err != nil {
		t.Fatal(err)
	}
	repo.tokenHash = sha256Bytes(token)
	protected := handler.RequireOwner(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		t.Fatal("supervisor reached owner handler")
	}))
	req := httptest.NewRequest(http.MethodPost, "/", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	recorder := httptest.NewRecorder()
	protected.ServeHTTP(recorder, req)
	if recorder.Code != http.StatusForbidden {
		t.Fatalf("supervisor access returned %d, want 403", recorder.Code)
	}
}

func TestStaffCanUseReadAuthenticationMiddleware(t *testing.T) {
	repo := newMemoryRepository("supervisor")
	repo.user.MustChangePassword = false
	handler := New(repo)
	token, _, err := newToken()
	if err != nil {
		t.Fatal(err)
	}
	repo.tokenHash = sha256Bytes(token)
	protected := handler.Require(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	}))
	request := httptest.NewRequest(http.MethodGet, "/api/v1/events", nil)
	request.Header.Set("Authorization", "Bearer "+token)
	recorder := httptest.NewRecorder()
	protected.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusNoContent {
		t.Fatalf("supervisor read access returned %d, want 204", recorder.Code)
	}
}

func TestInactiveUserSessionIsRejectedOnEveryRequest(t *testing.T) {
	repo := newMemoryRepository("owner")
	repo.user.MustChangePassword = false
	handler := New(repo)
	token, _, err := newToken()
	if err != nil {
		t.Fatal(err)
	}
	repo.tokenHash = sha256Bytes(token)
	repo.user.Active = false
	recorder := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodGet, "/", nil)
	request.Header.Set("Authorization", "Bearer "+token)
	handler.Require(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		t.Fatal("inactive session reached protected handler")
	})).ServeHTTP(recorder, request)
	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf("inactive session returned %d", recorder.Code)
	}
}

func TestLogoutRevokesBearerSession(t *testing.T) {
	repo := newMemoryRepository("owner")
	handler := New(repo)
	login, _ := performLogin(t, handler)
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/logout", nil)
	req.Header.Set("Authorization", "Bearer "+login.Token)
	recorder := httptest.NewRecorder()
	handler.Logout(recorder, req)
	if recorder.Code != http.StatusOK || !repo.revoked {
		t.Fatalf("logout did not revoke session: status=%d revoked=%t", recorder.Code, repo.revoked)
	}

	sessionRequest := httptest.NewRequest(http.MethodGet, "/api/v1/auth/session", nil)
	sessionRequest.Header.Set("Authorization", "Bearer "+login.Token)
	sessionRecorder := httptest.NewRecorder()
	handler.Session(sessionRecorder, sessionRequest)
	if sessionRecorder.Code != http.StatusUnauthorized {
		t.Fatalf("revoked session returned %d, want 401", sessionRecorder.Code)
	}
}

func TestChangePasswordRequiresCurrentAndStrongPassword(t *testing.T) {
	repo := newMemoryRepository("owner")
	handler := New(repo)
	login, _ := performLogin(t, handler)
	request := httptest.NewRequest(http.MethodPost, "/api/v1/auth/change-password",
		strings.NewReader(`{"current_password":"initial-password","new_password":"a-much-better-password"}`))
	request.Header.Set("Authorization", "Bearer "+login.Token)
	recorder := httptest.NewRecorder()
	handler.Require(http.HandlerFunc(handler.ChangePassword)).ServeHTTP(recorder, request)
	if recorder.Code != http.StatusOK || repo.user.MustChangePassword {
		t.Fatalf("password change failed: %d %s", recorder.Code, recorder.Body)
	}
}

func TestIncorrectCurrentPasswordIsBadRequest(t *testing.T) {
	repo := newMemoryRepository("owner")
	repo.user.MustChangePassword = false
	handler := New(repo)
	token, _, err := newToken()
	if err != nil {
		t.Fatal(err)
	}
	repo.tokenHash = sha256Bytes(token)
	request := httptest.NewRequest(http.MethodPost, "/api/v1/auth/change-password",
		strings.NewReader(`{"current_password":"wrong-password","new_password":"a-much-better-password"}`))
	request.Header.Set("Authorization", "Bearer "+token)
	recorder := httptest.NewRecorder()
	handler.Require(http.HandlerFunc(handler.ChangePassword)).ServeHTTP(recorder, request)
	if recorder.Code != http.StatusBadRequest {
		t.Fatalf("incorrect current password returned %d, want 400", recorder.Code)
	}
}

func TestLoginUsesGenericFailureAndLimitsAttempts(t *testing.T) {
	repo := newMemoryRepository("owner")
	handler := New(repo)
	for attempt := 0; attempt < maxLoginAttempts; attempt++ {
		req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/login",
			strings.NewReader(`{"username":"owner","password":"wrong"}`))
		recorder := httptest.NewRecorder()
		handler.Login(recorder, req)
		if recorder.Code != http.StatusUnauthorized || !strings.Contains(recorder.Body.String(), "Invalid username or password") {
			t.Fatalf("attempt %d leaked credential state: %d %s", attempt, recorder.Code, recorder.Body)
		}
	}
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/login",
		strings.NewReader(`{"username":"owner","password":"initial-password"}`))
	recorder := httptest.NewRecorder()
	handler.Login(recorder, req)
	if recorder.Code != http.StatusTooManyRequests {
		t.Fatalf("expected login rate limit, got %d", recorder.Code)
	}
}

func TestUnknownAndInactiveUserLoginFailuresAreIndistinguishable(t *testing.T) {
	tests := []struct {
		name       string
		username   string
		deactivate bool
	}{
		{name: "unknown user", username: "missing-user"},
		{name: "inactive user", username: "owner", deactivate: true},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			repo := newMemoryRepository("owner")
			if test.deactivate {
				repo.user.Active = false
			}
			handler := New(repo)
			request := httptest.NewRequest(
				http.MethodPost,
				"/api/v1/auth/login",
				strings.NewReader(`{"username":"`+test.username+`","password":"initial-password"}`),
			)
			recorder := httptest.NewRecorder()

			handler.Login(recorder, request)

			if recorder.Code != http.StatusUnauthorized ||
				!strings.Contains(recorder.Body.String(), "Invalid username or password") {
				t.Fatalf("login exposed user state: %d %s", recorder.Code, recorder.Body)
			}
		})
	}
}

func TestAdminUserCreateAndResetValidateInput(t *testing.T) {
	repo := newMemoryRepository("owner")
	handler := New(repo)
	actor := context.WithValue(context.Background(), contextKey{}, repo.user)
	request := httptest.NewRequest(http.MethodPost, "/api/v1/users",
		strings.NewReader(`{"username":"supervisor-one","role":"supervisor","password":"strong-enough-password"}`)).WithContext(actor)
	recorder := httptest.NewRecorder()
	handler.CreateUser(recorder, request)
	if recorder.Code != http.StatusCreated || !repo.created {
		t.Fatalf("create user failed: %d %s", recorder.Code, recorder.Body)
	}
	request = httptest.NewRequest(http.MethodPost, "/api/v1/users/2/reset-password",
		strings.NewReader(`{"password":"short"}`)).WithContext(actor)
	recorder = httptest.NewRecorder()
	handler.ResetPassword(recorder, request)
	if recorder.Code != http.StatusBadRequest || repo.reset {
		t.Fatalf("weak reset password was not rejected: %d", recorder.Code)
	}
	request = httptest.NewRequest(http.MethodPost, "/api/v1/users/2/reset-password",
		strings.NewReader(`{"password":"another-strong-password"}`)).WithContext(actor)
	recorder = httptest.NewRecorder()
	handler.ResetPassword(recorder, request)
	if recorder.Code != http.StatusOK || !repo.reset || !strings.Contains(recorder.Body.String(), `"reset":true`) {
		t.Fatalf("valid reset failed: %d %s", recorder.Code, recorder.Body)
	}
}

func TestUpdateUserAcceptsIsActiveOnly(t *testing.T) {
	repo := newMemoryRepository("owner")
	handler := New(repo)
	actor := context.WithValue(context.Background(), contextKey{}, repo.user)
	request := httptest.NewRequest(http.MethodPatch, "/api/v1/users/2",
		strings.NewReader(`{"is_active":false}`)).WithContext(actor)
	recorder := httptest.NewRecorder()

	handler.UpdateUser(recorder, request)

	if recorder.Code != http.StatusOK || !repo.updated || repo.updateActive == nil || *repo.updateActive ||
		!strings.Contains(recorder.Body.String(), `"is_active":false`) {
		t.Fatalf("is_active-only update failed: %d %s", recorder.Code, recorder.Body)
	}
}

func TestPasswordLengthIsValidatedInBytes(t *testing.T) {
	if err := validatePassword(strings.Repeat("a", 12)); err != nil {
		t.Fatalf("12-byte password rejected: %v", err)
	}
	if err := validatePassword(strings.Repeat("a", 72)); err != nil {
		t.Fatalf("72-byte password rejected: %v", err)
	}
	if err := validatePassword(strings.Repeat("a", 11)); err == nil {
		t.Fatal("11-byte password was accepted")
	}
	if err := validatePassword(strings.Repeat("a", 73)); err == nil {
		t.Fatal("73-byte password was accepted")
	}
	if err := validatePassword(strings.Repeat("é", 6)); err != nil {
		t.Fatalf("12-byte UTF-8 password was rejected: %v", err)
	}
}

func TestMissingSessionIsUnauthorized(t *testing.T) {
	handler := New(newMemoryRepository("owner"))
	recorder := httptest.NewRecorder()
	handler.Require(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		t.Fatal("unauthenticated request reached handler")
	})).ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/", nil))
	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf("unauthenticated request returned %d", recorder.Code)
	}
}

func TestMustChangePasswordBlocksProtectedRoutes(t *testing.T) {
	repo := newMemoryRepository("owner")
	handler := New(repo)
	token, _, err := newToken()
	if err != nil {
		t.Fatal(err)
	}
	repo.tokenHash = sha256Bytes(token)
	protected := handler.Require(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		t.Fatal("password-change-required user reached protected route")
	}))
	request := httptest.NewRequest(http.MethodGet, "/api/v1/events", nil)
	request.Header.Set("Authorization", "Bearer "+token)
	recorder := httptest.NewRecorder()
	protected.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusForbidden {
		t.Fatalf("protected route returned %d, want 403", recorder.Code)
	}
}

func TestUpdateFailureErrors(t *testing.T) {
	recorder := httptest.NewRecorder()
	writeUserMutationError(recorder, ErrLastOwner, "failure")
	if recorder.Code != http.StatusConflict {
		t.Fatalf("last-owner error returned %d", recorder.Code)
	}
	if errors.Is(ErrLastOwner, ErrNotFound) {
		t.Fatal("user mutation sentinel errors overlap")
	}
}

func sha256Bytes(token string) []byte {
	hash := sha256.Sum256([]byte(token))
	return hash[:]
}
