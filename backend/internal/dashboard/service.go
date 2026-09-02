package dashboard

import (
	"context"
	"database/sql"
	"fmt"
	"time"
)

type Repository struct{ db *sql.DB }

func NewRepository(db *sql.DB) *Repository { return &Repository{db: db} }

func (r *Repository) Summary(ctx context.Context, from, to string) (Summary, error) {
	result := Summary{From: from, To: to, Events: make([]Event, 0)}
	err := r.db.QueryRowContext(ctx, `
		SELECT COUNT(*), COUNT(*) FILTER (WHERE status = 'upcoming'), COUNT(*) FILTER (WHERE status = 'running'), COUNT(*) FILTER (WHERE status = 'completed'),
			COALESCE(SUM(income.total_income), 0)::numeric(12,2)::text, COALESCE(SUM(expenses.total_expenses), 0)::numeric(12,2)::text,
			(COALESCE(SUM(income.total_income), 0) - COALESCE(SUM(expenses.total_expenses), 0))::numeric(12,2)::text
		FROM events e
		LEFT JOIN (SELECT event_id, SUM(amount) AS total_income FROM event_income GROUP BY event_id) income ON income.event_id = e.id
		LEFT JOIN (SELECT event_id, SUM(amount) AS total_expenses FROM event_expenses GROUP BY event_id) expenses ON expenses.event_id = e.id
		WHERE e.event_date >= $1::date AND e.event_date <= $2::date
	`, from, to).Scan(&result.EventCount, &result.UpcomingCount, &result.RunningCount, &result.CompletedCount, &result.TotalIncome, &result.TotalExpenses, &result.Profit)
	if err != nil {
		return Summary{}, err
	}

	rows, err := r.db.QueryContext(ctx, `
		SELECT e.id, e.title, e.event_date::text, e.venue, e.guest_count, e.status,
			COALESCE(income.total_income, 0)::numeric(12,2)::text, COALESCE(expenses.total_expenses, 0)::numeric(12,2)::text,
			(COALESCE(income.total_income, 0) - COALESCE(expenses.total_expenses, 0))::numeric(12,2)::text
		FROM events e
		LEFT JOIN (SELECT event_id, SUM(amount) AS total_income FROM event_income GROUP BY event_id) income ON income.event_id = e.id
		LEFT JOIN (SELECT event_id, SUM(amount) AS total_expenses FROM event_expenses GROUP BY event_id) expenses ON expenses.event_id = e.id
		WHERE e.event_date >= $1::date AND e.event_date <= $2::date
		ORDER BY e.event_date ASC, e.id ASC
	`, from, to)
	if err != nil {
		return Summary{}, err
	}
	defer rows.Close()
	for rows.Next() {
		var event Event
		if err := rows.Scan(&event.ID, &event.Title, &event.EventDate, &event.Venue, &event.GuestCount, &event.Status, &event.TotalIncome, &event.TotalExpenses, &event.Profit); err != nil {
			return Summary{}, err
		}
		result.Events = append(result.Events, event)
	}
	if err := rows.Err(); err != nil {
		return Summary{}, err
	}
	return result, nil
}

type Service struct{ repository *Repository }

func NewService(repository *Repository) *Service { return &Service{repository: repository} }

func (s *Service) Summary(ctx context.Context, from, to string) (Summary, error) {
	if from == "" {
		from = time.Now().Format("2006-01-02")
	}
	if to == "" {
		to = from
	}
	fromDate, fromErr := time.Parse("2006-01-02", from)
	toDate, toErr := time.Parse("2006-01-02", to)
	if fromErr != nil || toErr != nil || fromDate.After(toDate) {
		return Summary{}, fmt.Errorf("invalid date range")
	}
	return s.repository.Summary(ctx, from, to)
}
