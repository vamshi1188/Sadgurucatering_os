package events

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

type createEventRequest struct {
	Title      string `json:"title"`
	EventDate  string `json:"event_date"`
	Venue      string `json:"venue"`
	GuestCount int    `json:"guest_count"`
	Status     Status `json:"status"`
}

func (h *Handler) Create(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		response.WriteError(
			w,
			appErrors.NotFoundError("Resource not found"),
		)
		return
	}

	r.Body = http.MaxBytesReader(w, r.Body, 16*1024)

	var req createEventRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.WriteError(
			w,
			appErrors.InvalidRequest("Invalid request body"),
		)
		return
	}

	event, err := h.service.Create(
		r.Context(),
		CreateInput{
			Title:      req.Title,
			EventDate:  req.EventDate,
			Venue:      req.Venue,
			GuestCount: req.GuestCount,
			Status:     req.Status,
		},
	)
	if err != nil {
		response.WriteError(
			w,
			appErrors.InvalidRequest(err.Error()),
		)
		return
	}

	response.Write(
		w,
		http.StatusCreated,
		event,
		"",
	)
}

func (h *Handler) List(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		response.WriteError(
			w,
			appErrors.NotFoundError("Resource not found"),
		)
		return
	}

	events, err := h.service.List(r.Context())
	if err != nil {
		response.WriteError(
			w,
			appErrors.InternalError("Unable to list events"),
		)
		return
	}

	response.Write(
		w,
		http.StatusOK,
		events,
		"",
	)
}

func (h *Handler) GetByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		response.WriteError(
			w,
			appErrors.NotFoundError("Resource not found"),
		)
		return
	}

	const prefix = "/api/v1/events/"

	idText := strings.TrimPrefix(r.URL.Path, prefix)

	if idText == "" || strings.Contains(idText, "/") {
		response.WriteError(
			w,
			appErrors.NotFoundError("Resource not found"),
		)
		return
	}

	id, err := strconv.ParseInt(idText, 10, 64)
	if err != nil || id <= 0 {
		response.WriteError(
			w,
			appErrors.NotFoundError("Event not found"),
		)
		return
	}

	event, err := h.service.GetByID(r.Context(), id)
	if err == ErrNotFound {
		response.WriteError(
			w,
			appErrors.NotFoundError("Event not found"),
		)
		return
	}

	if err != nil {
		response.WriteError(
			w,
			appErrors.InternalError("Unable to retrieve event"),
		)
		return
	}

	response.Write(
		w,
		http.StatusOK,
		event,
		"",
	)
}

type updateEventStatusRequest struct {
	Status Status `json:"status"`
}

func (h *Handler) UpdateStatus(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch {
		response.WriteError(
			w,
			appErrors.NotFoundError("Resource not found"),
		)
		return
	}

	const prefix = "/api/v1/events/"

	idText := strings.TrimPrefix(r.URL.Path, prefix)
	idText = strings.TrimSuffix(idText, "/status")

	if idText == "" || strings.Contains(idText, "/") {
		response.WriteError(
			w,
			appErrors.NotFoundError("Resource not found"),
		)
		return
	}

	id, err := strconv.ParseInt(idText, 10, 64)
	if err != nil || id <= 0 {
		response.WriteError(
			w,
			appErrors.NotFoundError("Event not found"),
		)
		return
	}

	r.Body = http.MaxBytesReader(w, r.Body, 4096)

	var req updateEventStatusRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.WriteError(
			w,
			appErrors.InvalidRequest("Invalid request body"),
		)
		return
	}

	event, err := h.service.UpdateStatus(
		r.Context(),
		id,
		req.Status,
	)

	if err == ErrNotFound {
		response.WriteError(
			w,
			appErrors.NotFoundError("Event not found"),
		)
		return
	}

	if err != nil {
		response.WriteError(
			w,
			appErrors.InvalidRequest(err.Error()),
		)
		return
	}

	response.Write(
		w,
		http.StatusOK,
		event,
		"",
	)
}
