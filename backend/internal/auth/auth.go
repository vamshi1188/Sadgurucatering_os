package auth

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	appErrors "github.com/vamshi1188/Sadgurucatering_os/backend/internal/errors"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/response"
	"golang.org/x/crypto/bcrypt"
)

const (
	SessionDuration  = 24 * time.Hour
	maxLoginAttempts = 5
	loginWindow      = 15 * time.Minute
	maxLoginKeys     = 10000
)

var (
	ErrNotFound  = errors.New("not found")
	ErrConflict  = errors.New("conflict")
	ErrLastOwner = errors.New("last active owner")
)

type User struct {
	ID                 int64     `json:"id"`
	Username           string    `json:"username"`
	Role               string    `json:"role"`
	Active             bool      `json:"-"`
	MustChangePassword bool      `json:"must_change_password"`
	PasswordHash       string    `json:"-"`
	CreatedAt          time.Time `json:"-"`
}

type managedUser struct {
	ID                 int64     `json:"id"`
	Username           string    `json:"username"`
	Role               string    `json:"role"`
	Active             bool      `json:"is_active"`
	MustChangePassword bool      `json:"must_change_password"`
	CreatedAt          time.Time `json:"created_at"`
}

type Repository interface {
	BootstrapOwner(context.Context, string, string) error
	UserByUsername(context.Context, string) (User, error)
	CreateSession(context.Context, int64, []byte, time.Time, string) error
	UserForSession(context.Context, []byte) (User, error)
	RevokeSession(context.Context, []byte) error
	ChangePassword(context.Context, int64, string, []byte) error
	ListUsers(context.Context) ([]User, error)
	CreateUser(context.Context, string, string, string, int64) (User, error)
	UpdateUser(context.Context, int64, *string, *string, *bool, int64) (User, error)
	DeleteUser(context.Context, int64, int64) error
	ResetPassword(context.Context, int64, string, int64) error
}

type Handler struct {
	repo   Repository
	dummy  string
	mu     sync.Mutex
	failed map[string][]time.Time
}

type loginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type passwordChangeRequest struct {
	CurrentPassword string `json:"current_password"`
	NewPassword     string `json:"new_password"`
}

type createUserRequest struct {
	Username string `json:"username"`
	Role     string `json:"role"`
	Password string `json:"password"`
}

type updateUserRequest struct {
	Username *string `json:"username"`
	Role     *string `json:"role"`
	Active   *bool   `json:"active"`
	IsActive *bool   `json:"is_active"`
}

type resetPasswordRequest struct {
	Password string `json:"password"`
}

type loginResponse struct {
	Token string `json:"token"`
	User  User   `json:"user"`
}

type contextKey struct{}

func New(repositories ...Repository) *Handler {
	var repo Repository
	if len(repositories) > 0 {
		repo = repositories[0]
	}
	dummy, _ := bcrypt.GenerateFromPassword([]byte("constant-time-dummy-password"), bcrypt.DefaultCost)
	return &Handler{
		repo:   repo,
		dummy:  string(dummy),
		failed: make(map[string][]time.Time),
	}
}

func (h *Handler) Bootstrap(ctx context.Context, username, password string) error {
	if h.repo == nil {
		return errors.New("authentication repository is not configured")
	}
	return h.repo.BootstrapOwner(ctx, username, password)
}

func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		response.WriteError(w, appErrors.NotFoundError("Resource not found"))
		return
	}
	var req loginRequest
	if err := decodeJSON(w, r, &req, 4096); err != nil {
		response.WriteError(w, appErrors.InvalidRequest("Invalid request body"))
		return
	}
	req.Username = strings.TrimSpace(req.Username)
	key := loginKey(r, req.Username)
	if h.isLimited(key, time.Now()) {
		response.WriteError(w, appErrors.New("RATE_LIMITED", "Too many login attempts", http.StatusTooManyRequests))
		return
	}
	user := User{}
	var err error = ErrNotFound
	if h.repo != nil && req.Username != "" {
		user, err = h.repo.UserByUsername(r.Context(), req.Username)
	}
	hash := h.dummy
	if err == nil {
		hash = user.PasswordHash
	} else if !errors.Is(err, ErrNotFound) && h.repo != nil {
		_ = bcrypt.CompareHashAndPassword([]byte(h.dummy), []byte(req.Password))
		response.WriteError(w, appErrors.InternalError("Unable to authenticate"))
		return
	}
	match := bcrypt.CompareHashAndPassword([]byte(hash), []byte(req.Password)) == nil
	if h.repo == nil || req.Username == "" || req.Password == "" || err != nil || !user.Active || !match {
		h.recordFailure(key, time.Now())
		response.WriteError(w, appErrors.UnauthorizedError("Invalid username or password"))
		return
	}
	h.clearFailures(key)
	token, tokenHash, err := newToken()
	if err != nil {
		response.WriteError(w, appErrors.InternalError("Unable to create session"))
		return
	}
	if err := h.repo.CreateSession(r.Context(), user.ID, tokenHash, time.Now().Add(SessionDuration), user.PasswordHash); err != nil {
		response.WriteError(w, appErrors.InternalError("Unable to create session"))
		return
	}
	// The bearer token is intentionally returned only in the login response.
	response.Write(w, http.StatusOK, loginResponse{Token: token, User: publicUser(user)}, "")
}

func (h *Handler) Session(w http.ResponseWriter, r *http.Request) {
	user, ok := h.authenticate(r)
	if !ok {
		response.WriteError(w, appErrors.UnauthorizedError("Authentication required"))
		return
	}
	response.Write(w, http.StatusOK, map[string]any{"user": publicUser(user)}, "")
}

func (h *Handler) Logout(w http.ResponseWriter, r *http.Request) {
	if tokenHash, ok := h.tokenHashFromRequest(r); ok && h.repo != nil {
		if err := h.repo.RevokeSession(r.Context(), tokenHash); err != nil {
			response.WriteError(w, appErrors.InternalError("Unable to revoke session"))
			return
		}
	}
	response.Write(w, http.StatusOK, map[string]bool{"authenticated": false}, "")
}

func (h *Handler) ChangePassword(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		response.WriteError(w, appErrors.NotFoundError("Resource not found"))
		return
	}
	user, ok := h.authenticate(r)
	if !ok {
		response.WriteError(w, appErrors.UnauthorizedError("Authentication required"))
		return
	}
	var req passwordChangeRequest
	if err := decodeJSON(w, r, &req, 4096); err != nil {
		response.WriteError(w, appErrors.InvalidRequest("Invalid request body"))
		return
	}
	if bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.CurrentPassword)) != nil {
		response.WriteError(w, appErrors.InvalidRequest("Invalid current password"))
		return
	}
	if err := validatePassword(req.NewPassword); err != nil {
		response.WriteError(w, appErrors.InvalidRequest(err.Error()))
		return
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		response.WriteError(w, appErrors.InternalError("Unable to change password"))
		return
	}
	tokenHash, _ := h.tokenHashFromRequest(r)
	if err := h.repo.ChangePassword(r.Context(), user.ID, string(hash), tokenHash); err != nil {
		response.WriteError(w, appErrors.InternalError("Unable to change password"))
		return
	}
	user.MustChangePassword = false
	response.Write(w, http.StatusOK, map[string]any{"user": publicUser(user)}, "")
}

func (h *Handler) ListUsers(w http.ResponseWriter, r *http.Request) {
	users, err := h.repo.ListUsers(r.Context())
	if err != nil {
		response.WriteError(w, appErrors.InternalError("Unable to list users"))
		return
	}
	result := make([]managedUser, 0, len(users))
	for _, user := range users {
		result = append(result, managedUserFrom(user))
	}
	response.Write(w, http.StatusOK, result, "")
}

func (h *Handler) CreateUser(w http.ResponseWriter, r *http.Request) {
	var req createUserRequest
	if err := decodeJSON(w, r, &req, 8192); err != nil {
		response.WriteError(w, appErrors.InvalidRequest("Invalid request body"))
		return
	}
	req.Username = strings.TrimSpace(req.Username)
	if err := validateUsername(req.Username); err != nil {
		response.WriteError(w, appErrors.InvalidRequest(err.Error()))
		return
	}
	if req.Role != "owner" && req.Role != "supervisor" {
		response.WriteError(w, appErrors.InvalidRequest("Role must be owner or supervisor"))
		return
	}
	if err := validatePassword(req.Password); err != nil {
		response.WriteError(w, appErrors.InvalidRequest(err.Error()))
		return
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		response.WriteError(w, appErrors.InternalError("Unable to create user"))
		return
	}
	actor := currentUser(r).ID
	user, err := h.repo.CreateUser(r.Context(), req.Username, req.Role, string(hash), actor)
	if errors.Is(err, ErrConflict) {
		response.WriteError(w, appErrors.ConflictError("Username already exists"))
		return
	}
	if err != nil {
		response.WriteError(w, appErrors.InternalError("Unable to create user"))
		return
	}
	response.Write(w, http.StatusCreated, managedUserFrom(user), "")
}

func (h *Handler) UpdateUser(w http.ResponseWriter, r *http.Request) {
	id, ok := userIDFromPath(r.URL.Path, "/api/v1/users/")
	if !ok {
		response.WriteError(w, appErrors.NotFoundError("User not found"))
		return
	}
	var req updateUserRequest
	if err := decodeJSON(w, r, &req, 4096); err != nil {
		response.WriteError(w, appErrors.InvalidRequest("Invalid request body"))
		return
	}
	if req.Username == nil && req.Role == nil && req.Active == nil && req.IsActive == nil {
		response.WriteError(w, appErrors.InvalidRequest("At least one field is required"))
		return
	}
	if req.Username != nil {
		*req.Username = strings.TrimSpace(*req.Username)
		if err := validateUsername(*req.Username); err != nil {
			response.WriteError(w, appErrors.InvalidRequest(err.Error()))
			return
		}
	}
	if req.Role != nil && *req.Role != "owner" && *req.Role != "supervisor" {
		response.WriteError(w, appErrors.InvalidRequest("Role must be owner or supervisor"))
		return
	}
	active := req.Active
	if req.IsActive != nil {
		active = req.IsActive
	}
	user, err := h.repo.UpdateUser(r.Context(), id, req.Username, req.Role, active, currentUser(r).ID)
	if errors.Is(err, ErrNotFound) || errors.Is(err, ErrConflict) || errors.Is(err, ErrLastOwner) {
		writeUserMutationError(w, err, "Unable to update user")
		return
	}
	if err != nil {
		response.WriteError(w, appErrors.InternalError("Unable to update user"))
		return
	}
	response.Write(w, http.StatusOK, managedUserFrom(user), "")
}

func (h *Handler) DeleteUser(w http.ResponseWriter, r *http.Request) {
	id, ok := userIDFromPath(r.URL.Path, "/api/v1/users/")
	if !ok {
		response.WriteError(w, appErrors.NotFoundError("User not found"))
		return
	}
	err := h.repo.DeleteUser(r.Context(), id, currentUser(r).ID)
	if err == nil {
		w.WriteHeader(http.StatusNoContent)
		return
	}
	writeUserMutationError(w, err, "Unable to delete user")
}

func (h *Handler) ResetPassword(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimSuffix(r.URL.Path, "/reset-password")
	id, ok := userIDFromPath(path, "/api/v1/users/")
	if !ok {
		response.WriteError(w, appErrors.NotFoundError("User not found"))
		return
	}
	var req resetPasswordRequest
	if err := decodeJSON(w, r, &req, 4096); err != nil {
		response.WriteError(w, appErrors.InvalidRequest("Invalid request body"))
		return
	}
	if err := validatePassword(req.Password); err != nil {
		response.WriteError(w, appErrors.InvalidRequest(err.Error()))
		return
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		response.WriteError(w, appErrors.InternalError("Unable to reset password"))
		return
	}
	err = h.repo.ResetPassword(r.Context(), id, string(hash), currentUser(r).ID)
	if err != nil {
		writeUserMutationError(w, err, "Unable to reset password")
		return
	}
	response.Write(w, http.StatusOK, map[string]bool{"reset": true}, "")
}

func (h *Handler) Require(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		user, ok := h.authenticate(r)
		if !ok {
			response.WriteError(w, appErrors.UnauthorizedError("Authentication required"))
			return
		}
		if user.MustChangePassword && r.URL.Path != "/api/v1/auth/change-password" {
			response.WriteError(w, appErrors.New(
				"PASSWORD_CHANGE_REQUIRED",
				"Change your password before continuing",
				http.StatusForbidden,
			))
			return
		}
		ctx := context.WithValue(r.Context(), contextKey{}, user)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func (h *Handler) RequireOwner(next http.Handler) http.Handler {
	return h.Require(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if currentUser(r).Role != "owner" {
			response.WriteError(w, appErrors.ForbiddenError("Owner role required"))
			return
		}
		next.ServeHTTP(w, r)
	}))
}

func (h *Handler) authenticate(r *http.Request) (User, bool) {
	if h.repo == nil {
		return User{}, false
	}
	tokenHash, ok := h.tokenHashFromRequest(r)
	if !ok {
		return User{}, false
	}
	user, err := h.repo.UserForSession(r.Context(), tokenHash)
	return user, err == nil && user.Active
}

func (h *Handler) tokenHashFromRequest(r *http.Request) ([]byte, bool) {
	token := ""
	if header := r.Header.Get("Authorization"); strings.HasPrefix(header, "Bearer ") {
		token = strings.TrimSpace(strings.TrimPrefix(header, "Bearer "))
	}
	if token == "" || len(token) > 256 {
		return nil, false
	}
	hash := sha256.Sum256([]byte(token))
	return hash[:], true
}

func newToken() (string, []byte, error) {
	raw := make([]byte, 32)
	if _, err := rand.Read(raw); err != nil {
		return "", nil, err
	}
	token := base64.RawURLEncoding.EncodeToString(raw)
	hash := sha256.Sum256([]byte(token))
	return token, hash[:], nil
}

func decodeJSON(w http.ResponseWriter, r *http.Request, target any, limit int64) error {
	r.Body = http.MaxBytesReader(w, r.Body, limit)
	decoder := json.NewDecoder(r.Body)
	if err := decoder.Decode(target); err != nil {
		return err
	}
	var extra any
	if err := decoder.Decode(&extra); err != io.EOF {
		return fmt.Errorf("multiple JSON values")
	}
	return nil
}

func validateUsername(username string) error {
	if len(username) < 3 || len(username) > 64 {
		return errors.New("Username must be between 3 and 64 characters")
	}
	for _, char := range username {
		if !(char >= 'a' && char <= 'z') &&
			!(char >= 'A' && char <= 'Z') &&
			!(char >= '0' && char <= '9') &&
			char != '_' && char != '-' && char != '.' {
			return errors.New("Username may contain letters, numbers, dot, underscore, and hyphen")
		}
	}
	return nil
}

func validatePassword(password string) error {
	if len(password) < 12 || len(password) > 72 {
		return errors.New("Password must be between 12 and 72 bytes")
	}
	return nil
}

func publicUser(user User) User {
	user.PasswordHash = ""
	return user
}

func managedUserFrom(user User) managedUser {
	return managedUser{
		ID: user.ID, Username: user.Username, Role: user.Role,
		Active: user.Active, MustChangePassword: user.MustChangePassword,
		CreatedAt: user.CreatedAt,
	}
}

func currentUser(r *http.Request) User {
	user, _ := r.Context().Value(contextKey{}).(User)
	return user
}

func userIDFromPath(path, prefix string) (int64, bool) {
	value := strings.TrimPrefix(path, prefix)
	if value == "" || strings.Contains(value, "/") {
		return 0, false
	}
	id, err := strconv.ParseInt(value, 10, 64)
	return id, err == nil && id > 0
}

func writeUserMutationError(w http.ResponseWriter, err error, fallback string) {
	switch {
	case err == nil:
		w.WriteHeader(http.StatusNoContent)
	case errors.Is(err, ErrNotFound):
		response.WriteError(w, appErrors.NotFoundError("User not found"))
	case errors.Is(err, ErrConflict):
		response.WriteError(w, appErrors.ConflictError("Username already exists"))
	case errors.Is(err, ErrLastOwner):
		response.WriteError(w, appErrors.ConflictError("Cannot remove or deactivate the last active owner"))
	default:
		response.WriteError(w, appErrors.InternalError(fallback))
	}
}

func loginKey(r *http.Request, username string) string {
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		host = r.RemoteAddr
	}
	return strings.ToLower(host) + "\x00" + strings.ToLower(username)
}

func (h *Handler) isLimited(key string, now time.Time) bool {
	h.mu.Lock()
	defer h.mu.Unlock()
	attempts := h.prune(key, now)
	if len(h.failed) >= maxLoginKeys {
		for failedKey := range h.failed {
			h.prune(failedKey, now)
		}
		if _, exists := h.failed[key]; !exists && len(h.failed) >= maxLoginKeys {
			return true
		}
	}
	return len(attempts) >= maxLoginAttempts
}

func (h *Handler) recordFailure(key string, now time.Time) {
	h.mu.Lock()
	defer h.mu.Unlock()
	h.failed[key] = append(h.prune(key, now), now)
}

func (h *Handler) prune(key string, now time.Time) []time.Time {
	attempts := h.failed[key]
	cutoff := now.Add(-loginWindow)
	kept := attempts[:0]
	for _, attempt := range attempts {
		if attempt.After(cutoff) {
			kept = append(kept, attempt)
		}
	}
	if len(kept) == 0 {
		delete(h.failed, key)
	} else {
		h.failed[key] = kept
	}
	return kept
}

func (h *Handler) clearFailures(key string) {
	h.mu.Lock()
	delete(h.failed, key)
	h.mu.Unlock()
}
