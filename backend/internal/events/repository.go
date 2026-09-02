package events

import (
	"context"
	"database/sql"
	"errors"
)

var ErrNotFound = errors.New("event not found")

type Repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{db: db}
}

func (r *Repository) Create(
	ctx context.Context,
	title string,
	eventDate string,
	venue string,
	guestCount int,
	status Status,
) (Event, error) {
	var event Event

	err := r.db.QueryRowContext(
		ctx,
		`
		INSERT INTO events (
			title,
			event_date,
			venue,
			guest_count,
			status
		)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING
			id,
			title,
			event_date,
			venue,
			guest_count,
			status,
			created_at,
			updated_at
		`,
		title,
		eventDate,
		venue,
		guestCount,
		status,
	).Scan(
		&event.ID,
		&event.Title,
		&event.EventDate,
		&event.Venue,
		&event.GuestCount,
		&event.Status,
		&event.CreatedAt,
		&event.UpdatedAt,
	)

	return event, err
}

func (r *Repository) List(ctx context.Context) ([]Event, error) {
	rows, err := r.db.QueryContext(
		ctx,
		`
		SELECT
			id,
			title,
			event_date,
			venue,
			guest_count,
			status,
			created_at,
			updated_at
		FROM events
		ORDER BY event_date ASC, id ASC
		`,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	events := make([]Event, 0)

	for rows.Next() {
		var event Event

		if err := rows.Scan(
			&event.ID,
			&event.Title,
			&event.EventDate,
			&event.Venue,
			&event.GuestCount,
			&event.Status,
			&event.CreatedAt,
			&event.UpdatedAt,
		); err != nil {
			return nil, err
		}

		events = append(events, event)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return events, nil
}

func (r *Repository) GetByID(
	ctx context.Context,
	id int64,
) (Event, error) {
	var event Event

	err := r.db.QueryRowContext(
		ctx,
		`
		SELECT
			id,
			title,
			event_date,
			venue,
			guest_count,
			status,
			created_at,
			updated_at
		FROM events
		WHERE id = $1
		`,
		id,
	).Scan(
		&event.ID,
		&event.Title,
		&event.EventDate,
		&event.Venue,
		&event.GuestCount,
		&event.Status,
		&event.CreatedAt,
		&event.UpdatedAt,
	)

	if errors.Is(err, sql.ErrNoRows) {
		return Event{}, ErrNotFound
	}

	return event, err
}

func (r *Repository) UpdateStatus(
	ctx context.Context,
	id int64,
	status Status,
) (Event, error) {
	var event Event

	err := r.db.QueryRowContext(
		ctx,
		`
		UPDATE events
		SET
			status = $2,
			updated_at = NOW()
		WHERE id = $1
		RETURNING
			id,
			title,
			event_date,
			venue,
			guest_count,
			status,
			created_at,
			updated_at
		`,
		id,
		status,
	).Scan(
		&event.ID,
		&event.Title,
		&event.EventDate,
		&event.Venue,
		&event.GuestCount,
		&event.Status,
		&event.CreatedAt,
		&event.UpdatedAt,
	)

	if errors.Is(err, sql.ErrNoRows) {
		return Event{}, ErrNotFound
	}

	return event, err
}
