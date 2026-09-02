package events

import "time"

type Status string

const (
	StatusUpcoming  Status = "upcoming"
	StatusRunning   Status = "running"
	StatusCompleted Status = "completed"
)

func (s Status) Valid() bool {
	switch s {
	case StatusUpcoming, StatusRunning, StatusCompleted:
		return true
	default:
		return false
	}
}

type Event struct {
	ID         int64     `json:"id"`
	Title      string    `json:"title"`
	EventDate  string    `json:"event_date"`
	Venue      string    `json:"venue"`
	GuestCount int       `json:"guest_count"`
	Status     Status    `json:"status"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}
