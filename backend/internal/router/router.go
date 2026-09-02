package router

import (
	"net/http"
	"strings"

	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/auth"
	appErrors "github.com/vamshi1188/Sadgurucatering_os/backend/internal/errors"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/events"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/health"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/response"
)

type Router struct {
	apiRoutes map[string]http.Handler
	auth      *auth.Handler
	events    *events.Handler
}

func New(authHandler ...*auth.Handler) http.Handler {
	var handler *auth.Handler

	if len(authHandler) > 0 {
		handler = authHandler[0]
	}

	return NewWithEvents(handler, nil)
}

func NewWithEvents(
	authHandler *auth.Handler,
	eventHandler *events.Handler,
) http.Handler {
	router := &Router{
		apiRoutes: make(map[string]http.Handler),
		auth:      authHandler,
		events:    eventHandler,
	}

	router.registerV1Routes()

	return router
}

func (r *Router) registerV1Routes() {
	r.registerAPI(
		http.MethodGet,
		"/api/v1/health",
		http.HandlerFunc(health.Handler),
	)

	if r.auth != nil {
		r.registerAPI(
			http.MethodPost,
			"/api/v1/auth/login",
			http.HandlerFunc(r.auth.Login),
		)

		r.registerAPI(
			http.MethodGet,
			"/api/v1/auth/session",
			http.HandlerFunc(r.auth.Session),
		)

		r.registerAPI(
			http.MethodPost,
			"/api/v1/auth/logout",
			http.HandlerFunc(r.auth.Logout),
		)
	}

	if r.auth != nil && r.events != nil {
		r.registerAPI(
			http.MethodPost,
			"/api/v1/events",
			r.auth.Require(http.HandlerFunc(r.events.Create)),
		)

		r.registerAPI(
			http.MethodGet,
			"/api/v1/events",
			r.auth.Require(http.HandlerFunc(r.events.List)),
		)
	}
}

func (r *Router) registerAPI(
	method string,
	path string,
	handler http.Handler,
) {
	r.apiRoutes[method+" "+path] = handler
}

func (r *Router) ServeHTTP(
	w http.ResponseWriter,
	req *http.Request,
) {
	if handler, ok := r.apiRoutes[req.Method+" "+req.URL.Path]; ok {
		handler.ServeHTTP(w, req)
		return
	}

	if r.events != nil &&
		strings.HasPrefix(req.URL.Path, "/api/v1/events/") {
		if req.Method == http.MethodGet {
			if r.auth == nil {
				response.WriteError(
					w,
					appErrors.NotFoundError("Resource not found"),
				)
				return
			}

			r.auth.Require(
				http.HandlerFunc(r.events.GetByID),
			).ServeHTTP(w, req)
			return
		}
	}

	if r.events != nil &&
		strings.HasPrefix(req.URL.Path, "/api/v1/events/") &&
		strings.HasSuffix(req.URL.Path, "/status") {
		if req.Method == http.MethodPatch && r.auth != nil {
			r.auth.Require(
				http.HandlerFunc(r.events.UpdateStatus),
			).ServeHTTP(w, req)
			return
		}
	}

	if len(req.URL.Path) >= len("/api/") &&
		req.URL.Path[:len("/api/")] == "/api/" {
		response.WriteError(
			w,
			appErrors.NotFoundError("Resource not found"),
		)
		return
	}

	http.NotFound(w, req)
}
