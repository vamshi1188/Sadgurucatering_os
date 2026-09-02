package finance

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"regexp"
	"strings"
)

var (
	ErrNotFound      = errors.New("event not found")
	ErrInvalidAmount = errors.New("amount must be greater than zero")
	ErrInvalidInput  = errors.New("invalid finance input")
	amountPattern    = regexp.MustCompile(`^(?:0*[1-9]\d*)(?:\.\d{1,2})?$`)
)

type Entry struct {
	ID          int64  `json:"id"`
	EventID     int64  `json:"event_id"`
	Description string `json:"description"`
	Amount      string `json:"amount"`
	CreatedAt   string `json:"created_at"`
}

type Financials struct {
	EventID       int64   `json:"event_id"`
	TotalIncome   string  `json:"total_income"`
	TotalExpenses string  `json:"total_expenses"`
	Profit        string  `json:"profit"`
	Income        []Entry `json:"income"`
	Expenses      []Entry `json:"expenses"`
}

type Repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{db: db}
}

func validateInput(description, amount string) error {
	description = strings.TrimSpace(description)
	amount = strings.TrimSpace(amount)

	if description == "" || len(description) > 255 {
		return fmt.Errorf("%w: description is required", ErrInvalidInput)
	}

	if !amountPattern.MatchString(amount) {
		return ErrInvalidAmount
	}

	return nil
}

func (r *Repository) eventExists(ctx context.Context, eventID int64) (bool, error) {
	var exists bool

	err := r.db.QueryRowContext(
		ctx,
		`SELECT EXISTS(SELECT 1 FROM events WHERE id = $1)`,
		eventID,
	).Scan(&exists)

	return exists, err
}

func (r *Repository) AddIncome(
	ctx context.Context,
	eventID int64,
	description string,
	amount string,
) (Entry, error) {
	var entry Entry

	exists, err := r.eventExists(ctx, eventID)
	if err != nil {
		return Entry{}, err
	}
	if !exists {
		return Entry{}, ErrNotFound
	}

	err = r.db.QueryRowContext(
		ctx,
		`
		INSERT INTO event_income (event_id, description, amount)
		VALUES ($1, $2, $3::numeric)
		RETURNING id, event_id, description, amount::text, created_at::text
		`,
		eventID,
		strings.TrimSpace(description),
		strings.TrimSpace(amount),
	).Scan(
		&entry.ID,
		&entry.EventID,
		&entry.Description,
		&entry.Amount,
		&entry.CreatedAt,
	)

	return entry, err
}

func (r *Repository) AddExpense(
	ctx context.Context,
	eventID int64,
	description string,
	amount string,
) (Entry, error) {
	var entry Entry

	exists, err := r.eventExists(ctx, eventID)
	if err != nil {
		return Entry{}, err
	}
	if !exists {
		return Entry{}, ErrNotFound
	}

	err = r.db.QueryRowContext(
		ctx,
		`
		INSERT INTO event_expenses (event_id, description, amount)
		VALUES ($1, $2, $3::numeric)
		RETURNING id, event_id, description, amount::text, created_at::text
		`,
		eventID,
		strings.TrimSpace(description),
		strings.TrimSpace(amount),
	).Scan(
		&entry.ID,
		&entry.EventID,
		&entry.Description,
		&entry.Amount,
		&entry.CreatedAt,
	)

	return entry, err
}

func (r *Repository) GetFinancials(
	ctx context.Context,
	eventID int64,
) (Financials, error) {
	exists, err := r.eventExists(ctx, eventID)
	if err != nil {
		return Financials{}, err
	}
	if !exists {
		return Financials{}, ErrNotFound
	}

	result := Financials{
		EventID:  eventID,
		Income:   make([]Entry, 0),
		Expenses: make([]Entry, 0),
	}

	err = r.db.QueryRowContext(
		ctx,
		`
		SELECT
			COALESCE((SELECT SUM(amount) FROM event_income WHERE event_id = $1), 0)::numeric(12,2)::text,
			COALESCE((SELECT SUM(amount) FROM event_expenses WHERE event_id = $1), 0)::numeric(12,2)::text,
			(
				COALESCE((SELECT SUM(amount) FROM event_income WHERE event_id = $1), 0)
				-
				COALESCE((SELECT SUM(amount) FROM event_expenses WHERE event_id = $1), 0)
			)::numeric(12,2)::text
		`,
		eventID,
	).Scan(
		&result.TotalIncome,
		&result.TotalExpenses,
		&result.Profit,
	)
	if err != nil {
		return Financials{}, err
	}

	rows, err := r.db.QueryContext(
		ctx,
		`
		SELECT id, event_id, description, amount::text, created_at::text
		FROM event_income
		WHERE event_id = $1
		ORDER BY id ASC
		`,
		eventID,
	)
	if err != nil {
		return Financials{}, err
	}

	for rows.Next() {
		var entry Entry
		if err := rows.Scan(
			&entry.ID,
			&entry.EventID,
			&entry.Description,
			&entry.Amount,
			&entry.CreatedAt,
		); err != nil {
			rows.Close()
			return Financials{}, err
		}
		result.Income = append(result.Income, entry)
	}
	if err := rows.Err(); err != nil {
		rows.Close()
		return Financials{}, err
	}
	rows.Close()

	rows, err = r.db.QueryContext(
		ctx,
		`
		SELECT id, event_id, description, amount::text, created_at::text
		FROM event_expenses
		WHERE event_id = $1
		ORDER BY id ASC
		`,
		eventID,
	)
	if err != nil {
		return Financials{}, err
	}
	defer rows.Close()

	for rows.Next() {
		var entry Entry
		if err := rows.Scan(
			&entry.ID,
			&entry.EventID,
			&entry.Description,
			&entry.Amount,
			&entry.CreatedAt,
		); err != nil {
			return Financials{}, err
		}
		result.Expenses = append(result.Expenses, entry)
	}

	if err := rows.Err(); err != nil {
		return Financials{}, err
	}

	return result, nil
}

func (r *Repository) Validate(
	description string,
	amount string,
) error {
	return validateInput(description, amount)
}
