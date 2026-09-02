package finance

import (
	"context"
	"database/sql/driver"
	"errors"
	"regexp"
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
)

func newFinanceTestRepository(t *testing.T) (*Repository, sqlmock.Sqlmock, func()) {
	t.Helper()

	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("sqlmock.New() error = %v", err)
	}

	repo := NewRepository(db)

	return repo, mock, func() {
		db.Close()
	}
}

func TestRepositoryAddIncome(t *testing.T) {
	repo, mock, cleanup := newFinanceTestRepository(t)
	defer cleanup()

	mock.ExpectQuery(regexp.QuoteMeta(
		`SELECT EXISTS(SELECT 1 FROM events WHERE id = $1)`,
	)).
		WithArgs(int64(1)).
		WillReturnRows(sqlmock.NewRows([]string{"exists"}).AddRow(true))

	mock.ExpectQuery(regexp.QuoteMeta(
		`INSERT INTO event_income (event_id, description, amount)
		 VALUES ($1, $2, $3::numeric)
		 RETURNING id, event_id, description, amount::text, created_at::text`,
	)).
		WithArgs(int64(1), "Catering advance", "50000.00").
		WillReturnRows(sqlmock.NewRows(
			[]string{"id", "event_id", "description", "amount", "created_at"},
		).AddRow(
			int64(1),
			int64(1),
			"Catering advance",
			"50000.00",
			"2026-09-02 10:00:00+00",
		))

	entry, err := repo.AddIncome(
		context.Background(),
		1,
		"Catering advance",
		"50000.00",
	)
	if err != nil {
		t.Fatalf("AddIncome() error = %v", err)
	}

	if entry.ID != 1 {
		t.Errorf("ID = %d, want 1", entry.ID)
	}

	if entry.EventID != 1 {
		t.Errorf("EventID = %d, want 1", entry.EventID)
	}

	if entry.Amount != "50000.00" {
		t.Errorf("Amount = %q, want %q", entry.Amount, "50000.00")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("unmet SQL expectations: %v", err)
	}
}

func TestRepositoryAddExpense(t *testing.T) {
	repo, mock, cleanup := newFinanceTestRepository(t)
	defer cleanup()

	mock.ExpectQuery(regexp.QuoteMeta(
		`SELECT EXISTS(SELECT 1 FROM events WHERE id = $1)`,
	)).
		WithArgs(int64(1)).
		WillReturnRows(sqlmock.NewRows([]string{"exists"}).AddRow(true))

	mock.ExpectQuery(regexp.QuoteMeta(
		`INSERT INTO event_expenses (event_id, description, amount)
		 VALUES ($1, $2, $3::numeric)
		 RETURNING id, event_id, description, amount::text, created_at::text`,
	)).
		WithArgs(int64(1), "Food supplies", "18000.00").
		WillReturnRows(sqlmock.NewRows(
			[]string{"id", "event_id", "description", "amount", "created_at"},
		).AddRow(
			int64(1),
			int64(1),
			"Food supplies",
			"18000.00",
			"2026-09-02 11:00:00+00",
		))

	entry, err := repo.AddExpense(
		context.Background(),
		1,
		"Food supplies",
		"18000.00",
	)
	if err != nil {
		t.Fatalf("AddExpense() error = %v", err)
	}

	if entry.Amount != "18000.00" {
		t.Errorf("Amount = %q, want %q", entry.Amount, "18000.00")
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("unmet SQL expectations: %v", err)
	}
}

func TestRepositoryRejectsInvalidAmount(t *testing.T) {
	repo, mock, cleanup := newFinanceTestRepository(t)
	defer cleanup()

	tests := []string{
		"",
		"0",
		"0.00",
		"-1",
		"-100.00",
		"10.123",
		"abc",
	}

	for _, amount := range tests {
		t.Run(amount, func(t *testing.T) {
			err := repo.Validate("Food", amount)

			if err == nil {
				t.Fatalf("Validate(%q) error = nil, want error", amount)
			}

			if !errors.Is(err, ErrInvalidAmount) && !errors.Is(err, ErrInvalidInput) {
				t.Fatalf("Validate(%q) error = %v, want amount/input validation error", amount, err)
			}
		})
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("unexpected SQL calls: %v", err)
	}
}

func TestRepositoryRejectsEmptyDescription(t *testing.T) {
	repo, mock, cleanup := newFinanceTestRepository(t)
	defer cleanup()

	err := repo.Validate("", "100.00")
	if !errors.Is(err, ErrInvalidInput) {
		t.Fatalf("Validate() error = %v, want ErrInvalidInput", err)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("unexpected SQL calls: %v", err)
	}
}

func TestRepositoryAddIncomeRejectsMissingEvent(t *testing.T) {
	repo, mock, cleanup := newFinanceTestRepository(t)
	defer cleanup()

	mock.ExpectQuery(regexp.QuoteMeta(
		`SELECT EXISTS(SELECT 1 FROM events WHERE id = $1)`,
	)).
		WithArgs(int64(999)).
		WillReturnRows(sqlmock.NewRows([]string{"exists"}).AddRow(false))

	_, err := repo.AddIncome(
		context.Background(),
		999,
		"Advance",
		"10000.00",
	)

	if !errors.Is(err, ErrNotFound) {
		t.Fatalf("AddIncome() error = %v, want ErrNotFound", err)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("unmet SQL expectations: %v", err)
	}
}

func TestRepositoryGetFinancials(t *testing.T) {
	repo, mock, cleanup := newFinanceTestRepository(t)
	defer cleanup()

	mock.ExpectQuery(regexp.QuoteMeta(
		`SELECT EXISTS(SELECT 1 FROM events WHERE id = $1)`,
	)).
		WithArgs(int64(1)).
		WillReturnRows(sqlmock.NewRows([]string{"exists"}).AddRow(true))

	mock.ExpectQuery(regexp.QuoteMeta(
		`SELECT
			COALESCE((SELECT SUM(amount) FROM event_income WHERE event_id = $1), 0)::numeric(12,2)::text,
			COALESCE((SELECT SUM(amount) FROM event_expenses WHERE event_id = $1), 0)::numeric(12,2)::text,
			(
				COALESCE((SELECT SUM(amount) FROM event_income WHERE event_id = $1), 0)
				-
				COALESCE((SELECT SUM(amount) FROM event_expenses WHERE event_id = $1), 0)
			)::numeric(12,2)::text`,
	)).
		WithArgs(int64(1)).
		WillReturnRows(sqlmock.NewRows(
			[]string{"total_income", "total_expenses", "profit"},
		).AddRow("50000.00", "18000.00", "32000.00"))

	mock.ExpectQuery(regexp.QuoteMeta(
		`SELECT id, event_id, description, amount::text, created_at::text
		 FROM event_income
		 WHERE event_id = $1
		 ORDER BY id`,
	)).
		WithArgs(int64(1)).
		WillReturnRows(sqlmock.NewRows(
			[]string{"id", "event_id", "description", "amount", "created_at"},
		).AddRow(
			int64(1),
			int64(1),
			"Catering advance",
			"50000.00",
			"2026-09-02 10:00:00+00",
		))

	mock.ExpectQuery(regexp.QuoteMeta(
		`SELECT id, event_id, description, amount::text, created_at::text
		 FROM event_expenses
		 WHERE event_id = $1
		 ORDER BY id`,
	)).
		WithArgs(int64(1)).
		WillReturnRows(sqlmock.NewRows(
			[]string{"id", "event_id", "description", "amount", "created_at"},
		).AddRow(
			int64(1),
			int64(1),
			"Food supplies",
			"18000.00",
			"2026-09-02 11:00:00+00",
		))

	financials, err := repo.GetFinancials(context.Background(), 1)
	if err != nil {
		t.Fatalf("GetFinancials() error = %v", err)
	}

	if financials.EventID != 1 {
		t.Errorf("EventID = %d, want 1", financials.EventID)
	}

	if financials.TotalIncome != "50000.00" {
		t.Errorf("TotalIncome = %q, want %q", financials.TotalIncome, "50000.00")
	}

	if financials.TotalExpenses != "18000.00" {
		t.Errorf("TotalExpenses = %q, want %q", financials.TotalExpenses, "18000.00")
	}

	if financials.Profit != "32000.00" {
		t.Errorf("Profit = %q, want %q", financials.Profit, "32000.00")
	}

	if len(financials.Income) != 1 {
		t.Errorf("Income count = %d, want 1", len(financials.Income))
	}

	if len(financials.Expenses) != 1 {
		t.Errorf("Expenses count = %d, want 1", len(financials.Expenses))
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("unmet SQL expectations: %v", err)
	}
}

func TestRepositoryGetFinancialsMissingEvent(t *testing.T) {
	repo, mock, cleanup := newFinanceTestRepository(t)
	defer cleanup()

	mock.ExpectQuery(regexp.QuoteMeta(
		`SELECT EXISTS(SELECT 1 FROM events WHERE id = $1)`,
	)).
		WithArgs(int64(999)).
		WillReturnRows(sqlmock.NewRows([]string{"exists"}).AddRow(false))

	_, err := repo.GetFinancials(context.Background(), 999)
	if !errors.Is(err, ErrNotFound) {
		t.Fatalf("GetFinancials() error = %v, want ErrNotFound", err)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("unmet SQL expectations: %v", err)
	}
}

func TestAmountDriverValue(t *testing.T) {
	values := []string{
		"1",
		"100.00",
		"999999.99",
	}

	for _, value := range values {
		var v driver.Value = value
		if v != value {
			t.Errorf("driver value = %v, want %q", v, value)
		}
	}
}
