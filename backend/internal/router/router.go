package router

import (
	"net/http"
	"strings"

	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/auth"
	appErrors "github.com/vamshi1188/Sadgurucatering_os/backend/internal/errors"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/events"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/finance"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/health"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/response"
)

type Router struct {
	apiRoutes map[string]http.Handler
	auth      *auth.Handler
	events    *events.Handler
	finance   *finance.Handler
}

func New(authHandler ...*auth.Handler) http.Handler {
	var handler *auth.Handler

	if len(authHandler) > 0 {
		handler = authHandler[0]
	}

	return NewWithFinance(handler, nil, nil)
}

func NewWithEvents(
	authHandler *auth.Handler,
	eventHandler *events.Handler,
) http.Handler {
	return NewWithFinance(authHandler, eventHandler, nil)
}

func NewWithFinance(
	authHandler *auth.Handler,
	eventHandler *events.Handler,
	financeHandler *finance.Handler,
) http.Handler {
	router := &Router{
		apiRoutes: make(map[string]http.Handler),
		auth:      authHandler,
		events:    eventHandler,
		finance:   financeHandler,
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

	if r.auth != nil && r.finance != nil {
		r.registerAPI(
			http.MethodPost,
			"/api/v1/events/{id}/income",
			r.auth.Require(http.HandlerFunc(r.finance.AddIncome)),
		)

		r.registerAPI(
			http.MethodPost,
			"/api/v1/events/{id}/expenses",
			r.auth.Require(http.HandlerFunc(r.finance.AddExpense)),
		)

		r.registerAPI(
			http.MethodGet,
			"/api/v1/events/{id}/financials",
			r.auth.Require(http.HandlerFunc(r.finance.GetFinancials)),
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

	if r.finance != nil &&
		strings.HasPrefix(req.URL.Path, "/api/v1/events/") {
		if strings.HasSuffix(req.URL.Path, "/income") &&
			req.Method == http.MethodPost &&
			r.auth != nil {
			r.auth.Require(
				http.HandlerFunc(r.finance.AddIncome),
			).ServeHTTP(w, req)
			return
		}

		if strings.HasSuffix(req.URL.Path, "/expenses") &&
			req.Method == http.MethodPost &&
			r.auth != nil {
			r.auth.Require(
				http.HandlerFunc(r.finance.AddExpense),
			).ServeHTTP(w, req)
			return
		}

		if strings.HasSuffix(req.URL.Path, "/financials") &&
			req.Method == http.MethodGet &&
			r.auth != nil {
			r.auth.Require(
				http.HandlerFunc(r.finance.GetFinancials),
			).ServeHTTP(w, req)
			return
		}
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
