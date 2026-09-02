package dashboard

import (
	"net/http"

	appErrors "github.com/vamshi1188/Sadgurucatering_os/backend/internal/errors"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/response"
)

type Handler struct{ service *Service }

func NewHandler(service *Service) *Handler { return &Handler{service: service} }

func (h *Handler) Summary(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		response.WriteError(w, appErrors.NotFoundError("Resource not found"))
		return
	}
	summary, err := h.service.Summary(r.Context(), r.URL.Query().Get("from"), r.URL.Query().Get("to"))
	if err != nil {
		if err.Error() == "invalid date range" {
			response.WriteError(w, appErrors.InvalidRequest(err.Error()))
			return
		}
		response.WriteError(w, appErrors.InternalError("Unable to retrieve dashboard summary"))
		return
	}
	response.Write(w, http.StatusOK, summary, "")
}
