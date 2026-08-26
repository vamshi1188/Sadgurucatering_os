package router

import (
	"net/http"

	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/auth"
	appErrors "github.com/vamshi1188/Sadgurucatering_os/backend/internal/errors"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/health"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/response"
)

type Router struct {
	apiRoutes map[string]http.Handler
	auth      *auth.Handler
}

func New(authHandler ...*auth.Handler) http.Handler {
	var handler *auth.Handler

	if len(authHandler) > 0 {
		handler = authHandler[0]
	}

	router := &Router{
		apiRoutes: make(map[string]http.Handler),
		auth:      handler,
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
