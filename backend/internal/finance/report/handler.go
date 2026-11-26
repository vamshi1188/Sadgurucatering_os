package report

import (
	"net/http"
	"strconv"

	appErrors "github.com/vamshi1188/Sadgurucatering_os/backend/internal/errors"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/response"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

func (h *Handler) Summary(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		response.WriteError(w, appErrors.NotFoundError("Resource not found"))
		return
	}

	query := r.URL.Query()
	for key, values := range query {
		if key != "period" && key != "from" && key != "to" &&
			key != "page" && key != "page_size" {
			response.WriteError(w, appErrors.InvalidRequest("Invalid finance report parameters"))
			return
		}
		if len(values) != 1 {
			response.WriteError(w, appErrors.InvalidRequest("Invalid finance report parameters"))
			return
		}
	}

	page, err := parseQueryInt(query.Get("page"), 1)
	if err != nil {
		response.WriteError(w, appErrors.InvalidRequest("Invalid finance report page"))
		return
	}
	pageSize, err := parseQueryInt(query.Get("page_size"), DefaultPageSize)
	if err != nil {
		response.WriteError(w, appErrors.InvalidRequest("Invalid finance report page size"))
		return
	}

	result, err := h.service.Get(r.Context(), Filter{
		Period:   query.Get("period"),
		From:     query.Get("from"),
		To:       query.Get("to"),
		Page:     page,
		PageSize: pageSize,
	})
	if err != nil {
		if err == ErrInvalidFilter {
			response.WriteError(w, appErrors.InvalidRequest("Invalid finance report filters"))
			return
		}
		response.WriteError(w, appErrors.InternalError("Unable to retrieve finance report"))
		return
	}

	response.Write(w, http.StatusOK, result, "")
}

func parseQueryInt(value string, fallback int) (int, error) {
	if value == "" {
		return fallback, nil
	}
	parsed, err := strconv.Atoi(value)
	if err != nil {
		return 0, err
	}
	return parsed, nil
}
