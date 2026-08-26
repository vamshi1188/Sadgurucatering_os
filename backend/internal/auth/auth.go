package auth

import (
	"crypto/hmac"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"

	appErrors "github.com/vamshi1188/Sadgurucatering_os/backend/internal/errors"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/response"
)

const (
	CookieName      = "sadguru_session"
	SessionDuration = 24 * time.Hour
)

type Config struct {
	Password string
	Secret   string
	Secure   bool
}

type Handler struct {
	cfg Config
}

type loginRequest struct {
	Password string `json:"password"`
}

type sessionPayload struct {
	IssuedAt int64 `json:"issued_at"`
}

func New(cfg Config) *Handler {
	return &Handler{cfg: cfg}
}

func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		response.WriteError(
			w,
			appErrors.NotFoundError("Resource not found"),
		)
		return
	}

	var req loginRequest

	r.Body = http.MaxBytesReader(w, r.Body, 4096)

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.WriteError(
			w,
			appErrors.InvalidRequest("Invalid request body"),
		)
		return
	}

	if h.cfg.Password == "" || h.cfg.Secret == "" {
		response.WriteError(
			w,
			appErrors.InternalError("Authentication is not configured"),
		)
		return
	}

	if h.cfg.Password == "" || subtle.ConstantTimeCompare(
		[]byte(req.Password),
		[]byte(h.cfg.Password),
	) != 1 {
		response.WriteError(
			w,
			appErrors.UnauthorizedError("Invalid password"),
		)
		return
	}

	value, err := h.sign(sessionPayload{
		IssuedAt: time.Now().Unix(),
	})
	if err != nil {
		response.WriteError(
			w,
			appErrors.InternalError("Unable to create session"),
		)
		return
	}

	http.SetCookie(w, &http.Cookie{
		Name:     CookieName,
		Value:    value,
		Path:     "/",
		HttpOnly: true,
		Secure:   h.cfg.Secure,
		SameSite: http.SameSiteLaxMode,
		MaxAge:   int(SessionDuration.Seconds()),
	})

	response.Write(
		w,
		http.StatusOK,
		map[string]bool{"authenticated": true},
		"",
	)
}

func (h *Handler) Session(w http.ResponseWriter, r *http.Request) {
	if _, ok := h.sessionFromRequest(r); !ok {
		response.WriteError(
			w,
			appErrors.UnauthorizedError("Authentication required"),
		)
		return
	}

	response.Write(
		w,
		http.StatusOK,
		map[string]bool{"authenticated": true},
		"",
	)
}

func (h *Handler) Logout(w http.ResponseWriter, r *http.Request) {
	http.SetCookie(w, &http.Cookie{
		Name:     CookieName,
		Value:    "",
		Path:     "/",
		HttpOnly: true,
		Secure:   h.cfg.Secure,
		SameSite: http.SameSiteLaxMode,
		MaxAge:   -1,
	})

	response.Write(
		w,
		http.StatusOK,
		map[string]bool{"authenticated": false},
		"",
	)
}

func (h *Handler) Require(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if _, ok := h.sessionFromRequest(r); !ok {
			response.WriteError(
				w,
				appErrors.UnauthorizedError("Authentication required"),
			)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func (h *Handler) sessionFromRequest(
	r *http.Request,
) (sessionPayload, bool) {
	cookie, err := r.Cookie(CookieName)
	if err != nil {
		return sessionPayload{}, false
	}

	return h.verify(cookie.Value)
}

func (h *Handler) sign(payload sessionPayload) (string, error) {
	data, err := json.Marshal(payload)
	if err != nil {
		return "", err
	}

	encoded := base64.RawURLEncoding.EncodeToString(data)

	mac := hmac.New(sha256.New, []byte(h.cfg.Secret))
	_, _ = mac.Write([]byte(encoded))

	signature := base64.RawURLEncoding.EncodeToString(mac.Sum(nil))

	return encoded + "." + signature, nil
}

func (h *Handler) verify(value string) (sessionPayload, bool) {
	parts := strings.Split(value, ".")

	if len(parts) != 2 || h.cfg.Secret == "" {
		return sessionPayload{}, false
	}

	mac := hmac.New(sha256.New, []byte(h.cfg.Secret))
	_, _ = mac.Write([]byte(parts[0]))

	expected := mac.Sum(nil)

	provided, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return sessionPayload{}, false
	}

	if subtle.ConstantTimeCompare(expected, provided) != 1 {
		return sessionPayload{}, false
	}

	data, err := base64.RawURLEncoding.DecodeString(parts[0])
	if err != nil {
		return sessionPayload{}, false
	}

	var payload sessionPayload

	if err := json.Unmarshal(data, &payload); err != nil {
		return sessionPayload{}, false
	}

	now := time.Now().Unix()

	age := now - payload.IssuedAt

	if payload.IssuedAt <= 0 ||
		age < 0 ||
		age > int64(SessionDuration.Seconds()) {
		return sessionPayload{}, false
	}

	return payload, true
}

func ConfigFromEnv(
	password string,
	secret string,
	secureValue string,
) Config {
	secure, _ := strconv.ParseBool(secureValue)

	return Config{
		Password: password,
		Secret:   secret,
		Secure:   secure,
	}
}
