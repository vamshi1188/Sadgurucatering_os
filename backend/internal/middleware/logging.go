package middleware

import (
	"net/http"
	"time"

	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/logger"
)

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (r *statusRecorder) WriteHeader(status int) {
	r.status = status
	r.ResponseWriter.WriteHeader(status)
}

func (r *statusRecorder) Write(body []byte) (int, error) {
	if r.status == 0 {
		r.status = http.StatusOK
	}

	return r.ResponseWriter.Write(body)
}

func RequestLogger(log *logger.Logger) Middleware {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()

			recorder := &statusRecorder{
				ResponseWriter: w,
			}

			next.ServeHTTP(recorder, r)

			status := recorder.status

			if status == 0 {
				status = http.StatusOK
			}

			durationMS := float64(time.Since(start).Microseconds()) / 1000

			if log != nil {
				log.Request(
					r.Method,
					r.URL.Path,
					status,
					durationMS,
				)
			}
		})
	}
}
