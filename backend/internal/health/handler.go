package health

import (
	"net/http"

	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/response"
)

func Handler(w http.ResponseWriter, r *http.Request) {
	response.Write(
		w,
		http.StatusOK,
		NewResponse(),
		r.Header.Get("X-Request-ID"),
	)
}
