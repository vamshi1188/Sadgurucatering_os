package middleware

import (
	"net/http"

	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/response"
)

func Recovery(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if recovered := recover(); recovered != nil {
				response.WriteError(
					w,
					panicError{},
				)
			}
		}()

		next.ServeHTTP(w, r)
	})
}

type panicError struct{}

func (panicError) Error() string {
	return "internal server panic"
}
