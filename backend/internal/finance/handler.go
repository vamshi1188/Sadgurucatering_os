package finance

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	appErrors "github.com/vamshi1188/Sadgurucatering_os/backend/internal/errors"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/response"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

type entryRequest struct {
	Description string `json:"description"`
	Amount      string `json:"amount"`
}

func eventIDFromPath(path string, suffix string) (int64, bool) {
	const prefix = "/api/v1/events/"

	value := strings.TrimPrefix(path, prefix)
	value = strings.TrimSuffix(value, suffix)

	if value == "" || strings.Contains(value, "/") {
		return 0, false
	}

	id, err := strconv.ParseInt(value, 10, 64)
	return id, err == nil && id > 0
}

func decodeEntryRequest(w http.ResponseWriter, r *http.Request) (entryRequest, bool) {
	r.Body = http.MaxBytesReader(w, r.Body, 4096)

	var req entryRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.WriteError(
			w,
			appErrors.InvalidRequest("Invalid request body"),
		)
		return entryRequest{}, false
	}

	return req, true
}

func (h *Handler) AddIncome(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		response.WriteError(w, appErrors.NotFoundError("Resource not found"))
		return
	}

	eventID, ok := eventIDFromPath(r.URL.Path, "/income")
	if !ok {
		response.WriteError(w, appErrors.NotFoundError("Event not found"))
		return
	}

	req, ok := decodeEntryRequest(w, r)
	if !ok {
		return
	}

	entry, err := h.service.AddIncome(
		r.Context(),
		eventID,
		req.Description,
		req.Amount,
	)
	if err == ErrNotFound {
		response.WriteError(w, appErrors.NotFoundError("Event not found"))
		return
	}
	if err != nil {
		response.WriteError(w, appErrors.InvalidRequest(err.Error()))
		return
	}

	response.Write(w, http.StatusCreated, entry, "")
}

func (h *Handler) AddExpense(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		response.WriteError(w, appErrors.NotFoundError("Resource not found"))
		return
	}

	eventID, ok := eventIDFromPath(r.URL.Path, "/expenses")
	if !ok {
		response.WriteError(w, appErrors.NotFoundError("Event not found"))
		return
	}

	req, ok := decodeEntryRequest(w, r)
	if !ok {
		return
	}

	entry, err := h.service.AddExpense(
		r.Context(),
		eventID,
		req.Description,
		req.Amount,
	)
	if err == ErrNotFound {
		response.WriteError(w, appErrors.NotFoundError("Event not found"))
		return
	}
	if err != nil {
		response.WriteError(w, appErrors.InvalidRequest(err.Error()))
		return
	}

	response.Write(w, http.StatusCreated, entry, "")
}

func (h *Handler) GetFinancials(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		response.WriteError(w, appErrors.NotFoundError("Resource not found"))
		return
	}

	eventID, ok := eventIDFromPath(r.URL.Path, "/financials")
	if !ok {
		response.WriteError(w, appErrors.NotFoundError("Event not found"))
		return
	}

	financials, err := h.service.GetFinancials(r.Context(), eventID)
	if err == ErrNotFound {
		response.WriteError(w, appErrors.NotFoundError("Event not found"))
		return
	}
	if err != nil {
		response.WriteError(
			w,
			appErrors.InternalError("Unable to retrieve event financials"),
		)
		return
	}

	response.Write(w, http.StatusOK, financials, "")
}
