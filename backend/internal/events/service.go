package events

import (
	"context"
	"fmt"
	"strings"
	"time"
)

type Service struct {
	repository *Repository
}

func NewService(repository *Repository) *Service {
	return &Service{repository: repository}
}

type CreateInput struct {
	Title      string
	EventDate  string
	Venue      string
	GuestCount int
	Status     Status
}

func (s *Service) Create(
	ctx context.Context,
	input CreateInput,
) (Event, error) {
	if err := s.validateCreateInput(&input); err != nil {
		return Event{}, err
	}

	return s.repository.Create(
		ctx,
		input.Title,
		input.EventDate,
		input.Venue,
		input.GuestCount,
		input.Status,
	)
}

func (s *Service) validateCreateInput(input *CreateInput) error {
	input.Title = strings.TrimSpace(input.Title)
	input.Venue = strings.TrimSpace(input.Venue)

	if input.Title == "" {
		return fmt.Errorf("title is required")
	}

	if input.EventDate == "" {
		return fmt.Errorf("event_date is required")
	}
	if _, err := time.Parse("2006-01-02", input.EventDate); err != nil {
		return fmt.Errorf("event_date must be a valid date in YYYY-MM-DD format")
	}

	if input.Venue == "" {
		return fmt.Errorf("venue is required")
	}

	if input.GuestCount < 0 {
		return fmt.Errorf("guest_count must be greater than or equal to zero")
	}

	if input.Status == "" {
		input.Status = StatusUpcoming
	}

	if !input.Status.Valid() {
		return fmt.Errorf(
			"status must be one of upcoming, running, completed",
		)
	}

	return nil
}

func (s *Service) List(ctx context.Context) ([]Event, error) {
	return s.repository.List(ctx)
}

func (s *Service) GetByID(
	ctx context.Context,
	id int64,
) (Event, error) {
	return s.repository.GetByID(ctx, id)
}

func (s *Service) UpdateStatus(
	ctx context.Context,
	id int64,
	status Status,
) (Event, error) {
	if id <= 0 {
		return Event{}, fmt.Errorf("event id must be greater than zero")
	}

	if !status.Valid() {
		return Event{}, fmt.Errorf(
			"status must be one of upcoming, running, completed",
		)
	}

	event, err := s.repository.GetByID(ctx, id)
	if err != nil {
		return Event{}, err
	}

	if !validStatusTransition(event.Status, status) {
		return Event{}, fmt.Errorf(
			"invalid status transition from %s to %s",
			event.Status,
			status,
		)
	}

	return s.repository.UpdateStatus(ctx, id, status)
}

func validStatusTransition(
	from Status,
	to Status,
) bool {
	switch from {
	case StatusUpcoming:
		return to == StatusRunning
	case StatusRunning:
		return to == StatusCompleted
	case StatusCompleted:
		return false
	default:
		return false
	}
}
