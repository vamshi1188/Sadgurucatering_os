package report

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"
)

const (
	PeriodToday       = "today"
	PeriodThisMonth   = "this_month"
	PeriodLast30Days  = "last_30_days"
	PeriodCustom      = "custom"
	PeriodAllTime     = "all_time"
	DefaultPageSize   = 20
	MaximumPageSize   = 100
	MaximumPageNumber = 1_000_000
)

var ErrInvalidFilter = errors.New("invalid finance report filter")

type Transaction struct {
	Type        string `json:"type"`
	ID          int64  `json:"id"`
	EventID     int64  `json:"event_id"`
	EventTitle  string `json:"event_title"`
	Description string `json:"description"`
	Amount      string `json:"amount"`
	CreatedAt   string `json:"created_at"`
}

type EventBreakdown struct {
	EventID       int64  `json:"event_id"`
	Title         string `json:"title"`
	EventDate     string `json:"event_date"`
	Status        string `json:"status"`
	TotalIncome   string `json:"total_income"`
	TotalExpenses string `json:"total_expenses"`
	Profit        string `json:"profit"`
}

type TransactionPage struct {
	Page       int `json:"page"`
	PageSize   int `json:"page_size"`
	Total      int `json:"total"`
	TotalPages int `json:"total_pages"`
}

type Report struct {
	Period        string           `json:"period"`
	From          string           `json:"from,omitempty"`
	To            string           `json:"to,omitempty"`
	TotalIncome   string           `json:"total_income"`
	TotalExpenses string           `json:"total_expenses"`
	Profit        string           `json:"profit"`
	Events        []EventBreakdown `json:"events"`
	Transactions  []Transaction    `json:"transactions"`
	Pagination    TransactionPage  `json:"pagination"`
}

type Filter struct {
	Period   string
	From     string
	To       string
	Page     int
	PageSize int
}

type Repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{db: db}
}

func (r *Repository) Get(
	ctx context.Context,
	period string,
	from time.Time,
	toExclusive time.Time,
	hasRange bool,
	page int,
	pageSize int,
) (Report, error) {
	tx, err := r.db.BeginTx(ctx, &sql.TxOptions{
		Isolation: sql.LevelRepeatableRead,
		ReadOnly:  true,
	})
	if err != nil {
		return Report{}, fmt.Errorf("begin finance report snapshot: %w", err)
	}
	defer tx.Rollback()

	result := Report{
		Period:       period,
		Events:       make([]EventBreakdown, 0),
		Transactions: make([]Transaction, 0),
		Pagination: TransactionPage{
			Page:     page,
			PageSize: pageSize,
		},
	}

	var fromArg, toArg any
	if hasRange {
		fromArg = from
		toArg = toExclusive
		result.From = from.Format("2006-01-02")
		result.To = toExclusive.AddDate(0, 0, -1).Format("2006-01-02")
	}

	if err := tx.QueryRowContext(ctx, `
		WITH income_total AS (
			SELECT COALESCE(SUM(amount), 0.00) AS amount
			FROM event_income
			WHERE ($1::timestamptz IS NULL OR created_at >= $1)
			  AND ($2::timestamptz IS NULL OR created_at < $2)
		),
		expenses_total AS (
			SELECT COALESCE(SUM(amount), 0.00) AS amount
			FROM event_expenses
			WHERE ($1::timestamptz IS NULL OR created_at >= $1)
			  AND ($2::timestamptz IS NULL OR created_at < $2)
		)
		SELECT
			income_total.amount::text,
			expenses_total.amount::text,
			(income_total.amount - expenses_total.amount)::text
		FROM income_total CROSS JOIN expenses_total
	`, fromArg, toArg).Scan(
		&result.TotalIncome,
		&result.TotalExpenses,
		&result.Profit,
	); err != nil {
		return Report{}, fmt.Errorf("query finance totals: %w", err)
	}

	rows, err := tx.QueryContext(ctx, `
		WITH income AS (
			SELECT event_id, SUM(amount) AS total_income
			FROM event_income
			WHERE ($1::timestamptz IS NULL OR created_at >= $1)
			  AND ($2::timestamptz IS NULL OR created_at < $2)
			GROUP BY event_id
		),
		expenses AS (
			SELECT event_id, SUM(amount) AS total_expenses
			FROM event_expenses
			WHERE ($1::timestamptz IS NULL OR created_at >= $1)
			  AND ($2::timestamptz IS NULL OR created_at < $2)
			GROUP BY event_id
		)
		SELECT
			e.id,
			e.title,
			e.event_date::text,
			e.status,
			COALESCE(income.total_income, 0.00)::text,
			COALESCE(expenses.total_expenses, 0.00)::text,
			(COALESCE(income.total_income, 0.00) -
			 COALESCE(expenses.total_expenses, 0.00))::text
		FROM events e
		LEFT JOIN income ON income.event_id = e.id
		LEFT JOIN expenses ON expenses.event_id = e.id
		WHERE income.event_id IS NOT NULL OR expenses.event_id IS NOT NULL
		ORDER BY e.event_date DESC, e.id ASC
	`, fromArg, toArg)
	if err != nil {
		return Report{}, fmt.Errorf("query finance event breakdown: %w", err)
	}
	for rows.Next() {
		var event EventBreakdown
		if err := rows.Scan(
			&event.EventID,
			&event.Title,
			&event.EventDate,
			&event.Status,
			&event.TotalIncome,
			&event.TotalExpenses,
			&event.Profit,
		); err != nil {
			rows.Close()
			return Report{}, fmt.Errorf("scan finance event breakdown: %w", err)
		}
		result.Events = append(result.Events, event)
	}
	if err := rows.Err(); err != nil {
		rows.Close()
		return Report{}, fmt.Errorf("iterate finance event breakdown: %w", err)
	}
	if err := rows.Close(); err != nil {
		return Report{}, fmt.Errorf("close finance event breakdown: %w", err)
	}

	if err := tx.QueryRowContext(ctx, `
		SELECT COUNT(*)
		FROM (
			SELECT id FROM event_income
			WHERE ($1::timestamptz IS NULL OR created_at >= $1)
			  AND ($2::timestamptz IS NULL OR created_at < $2)
			UNION ALL
			SELECT id FROM event_expenses
			WHERE ($1::timestamptz IS NULL OR created_at >= $1)
			  AND ($2::timestamptz IS NULL OR created_at < $2)
		) transactions
	`, fromArg, toArg).Scan(&result.Pagination.Total); err != nil {
		return Report{}, fmt.Errorf("count finance transactions: %w", err)
	}
	if result.Pagination.Total > 0 {
		result.Pagination.TotalPages = (result.Pagination.Total + pageSize - 1) / pageSize
	}

	offset := (page - 1) * pageSize
	rows, err = tx.QueryContext(ctx, `
		SELECT
			transaction_type,
			id,
			event_id,
			event_title,
			description,
			amount,
			created_at::text
		FROM (
			SELECT
				'income'::text AS transaction_type,
				i.id,
				i.event_id,
				e.title AS event_title,
				i.description,
				i.amount::text AS amount,
				i.created_at
			FROM event_income i
			JOIN events e ON e.id = i.event_id
			WHERE ($1::timestamptz IS NULL OR i.created_at >= $1)
			  AND ($2::timestamptz IS NULL OR i.created_at < $2)
			UNION ALL
			SELECT
				'expense'::text AS transaction_type,
				x.id,
				x.event_id,
				e.title AS event_title,
				x.description,
				x.amount::text AS amount,
				x.created_at
			FROM event_expenses x
			JOIN events e ON e.id = x.event_id
			WHERE ($1::timestamptz IS NULL OR x.created_at >= $1)
			  AND ($2::timestamptz IS NULL OR x.created_at < $2)
		) all_transactions
		ORDER BY created_at DESC, transaction_type ASC, event_id ASC, id DESC
		LIMIT $3 OFFSET $4
	`, fromArg, toArg, pageSize, offset)
	if err != nil {
		return Report{}, fmt.Errorf("query finance transactions: %w", err)
	}
	for rows.Next() {
		var transaction Transaction
		if err := rows.Scan(
			&transaction.Type,
			&transaction.ID,
			&transaction.EventID,
			&transaction.EventTitle,
			&transaction.Description,
			&transaction.Amount,
			&transaction.CreatedAt,
		); err != nil {
			return Report{}, fmt.Errorf("scan finance transaction: %w", err)
		}
		result.Transactions = append(result.Transactions, transaction)
	}
	if err := rows.Err(); err != nil {
		return Report{}, fmt.Errorf("iterate finance transactions: %w", err)
	}
	if err := rows.Close(); err != nil {
		return Report{}, fmt.Errorf("close finance transactions: %w", err)
	}
	if err := tx.Commit(); err != nil {
		return Report{}, fmt.Errorf("commit finance report snapshot: %w", err)
	}

	return result, nil
}

type Service struct {
	repository *Repository
	now        func() time.Time
}

func NewService(repository *Repository) *Service {
	return &Service{repository: repository, now: time.Now}
}

func (s *Service) Get(ctx context.Context, filter Filter) (Report, error) {
	if filter.Page == 0 {
		filter.Page = 1
	}
	if filter.PageSize == 0 {
		filter.PageSize = DefaultPageSize
	}
	if filter.Page < 1 || filter.Page > MaximumPageNumber ||
		filter.PageSize < 1 || filter.PageSize > MaximumPageSize {
		return Report{}, ErrInvalidFilter
	}

	now := s.now().UTC()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
	var from, toExclusive time.Time
	hasRange := true

	switch filter.Period {
	case "", PeriodThisMonth:
		filter.Period = PeriodThisMonth
		from = time.Date(today.Year(), today.Month(), 1, 0, 0, 0, 0, time.UTC)
		toExclusive = from.AddDate(0, 1, 0)
	case PeriodToday:
		from = today
		toExclusive = today.AddDate(0, 0, 1)
	case PeriodLast30Days:
		from = today.AddDate(0, 0, -29)
		toExclusive = today.AddDate(0, 0, 1)
	case PeriodAllTime:
		hasRange = false
	case PeriodCustom:
		var err error
		from, err = parseDate(filter.From)
		if err != nil {
			return Report{}, ErrInvalidFilter
		}
		to, err := parseDate(filter.To)
		if err != nil || from.After(to) {
			return Report{}, ErrInvalidFilter
		}
		toExclusive = to.AddDate(0, 0, 1)
	default:
		return Report{}, ErrInvalidFilter
	}

	if filter.Period != PeriodCustom && (filter.From != "" || filter.To != "") {
		return Report{}, ErrInvalidFilter
	}

	return s.repository.Get(
		ctx,
		filter.Period,
		from,
		toExclusive,
		hasRange,
		filter.Page,
		filter.PageSize,
	)
}

func parseDate(value string) (time.Time, error) {
	parsed, err := time.Parse("2006-01-02", value)
	if err != nil || parsed.Format("2006-01-02") != value {
		return time.Time{}, ErrInvalidFilter
	}
	return parsed.UTC(), nil
}
