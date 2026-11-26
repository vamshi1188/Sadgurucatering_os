package report

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"regexp"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
)

func setupRepository(t *testing.T) (*Repository, sqlmock.Sqlmock, func()) {
	t.Helper()
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatal(err)
	}
	return NewRepository(db), mock, func() { _ = db.Close() }
}

func expectReportQueries(
	mock sqlmock.Sqlmock,
	from any,
	to any,
	pageSize int,
	offset int,
	totals *sqlmock.Rows,
	events *sqlmock.Rows,
	totalTransactions int,
	transactions *sqlmock.Rows,
) {
	mock.ExpectBegin()
	mock.ExpectQuery("(?s)WITH income_total AS").
		WithArgs(from, to).
		WillReturnRows(totals)
	mock.ExpectQuery("(?s)WITH income AS").
		WithArgs(from, to).
		WillReturnRows(events)
	mock.ExpectQuery("(?s)SELECT COUNT\\(\\*\\)").
		WithArgs(from, to).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(totalTransactions))
	mock.ExpectQuery("(?s)SELECT\\s+transaction_type.*ORDER BY created_at DESC, transaction_type ASC, event_id ASC, id DESC").
		WithArgs(from, to, pageSize, offset).
		WillReturnRows(transactions)
	mock.ExpectCommit()
}

func TestRepositoryGetAggregatesEventsAndPaginatesRecentTransactions(t *testing.T) {
	repository, mock, cleanup := setupRepository(t)
	defer cleanup()

	from := time.Date(2026, 9, 1, 0, 0, 0, 0, time.UTC)
	to := time.Date(2026, 10, 1, 0, 0, 0, 0, time.UTC)
	expectReportQueries(
		mock,
		from,
		to,
		1,
		1,
		sqlmock.NewRows([]string{"total_income", "total_expenses", "profit"}).
			AddRow("100.10", "200.20", "-100.10"),
		sqlmock.NewRows([]string{
			"event_id", "title", "event_date", "status",
			"total_income", "total_expenses", "profit",
		}).
			AddRow(2, "Event B", "2026-09-10", "running", "100.10", "200.20", "-100.10").
			AddRow(1, "Event A", "2026-09-09", "completed", "0.00", "50.00", "-50.00"),
		3,
		sqlmock.NewRows([]string{
			"type", "id", "event_id", "event_title", "description", "amount", "created_at",
		}).AddRow(
			"expense", 10, 2, "Event B", "Supplies", "200.20", "2026-09-20 12:00:00+00",
		),
	)

	result, err := repository.Get(
		context.Background(),
		PeriodCustom,
		from,
		to,
		true,
		2,
		1,
	)
	if err != nil {
		t.Fatal(err)
	}
	if result.TotalIncome != "100.10" || result.TotalExpenses != "200.20" ||
		result.Profit != "-100.10" {
		t.Fatalf("unexpected exact financial totals: %+v", result)
	}
	if result.From != "2026-09-01" || result.To != "2026-09-30" {
		t.Fatalf("unexpected inclusive date range: %s to %s", result.From, result.To)
	}
	if len(result.Events) != 2 || result.Events[1].TotalIncome != "0.00" {
		t.Fatalf("expected event-wise aggregates including expense-only event: %+v", result.Events)
	}
	if len(result.Transactions) != 1 || result.Transactions[0].Type != "expense" {
		t.Fatalf("unexpected transaction page: %+v", result.Transactions)
	}
	if result.Pagination.Page != 2 || result.Pagination.PageSize != 1 ||
		result.Pagination.Total != 3 || result.Pagination.TotalPages != 3 {
		t.Fatalf("unexpected pagination: %+v", result.Pagination)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

func TestRepositoryAllTimeEmptyReportUsesZeroTotalsAndEmptyArrays(t *testing.T) {
	repository, mock, cleanup := setupRepository(t)
	defer cleanup()

	expectReportQueries(
		mock,
		nil,
		nil,
		DefaultPageSize,
		0,
		sqlmock.NewRows([]string{"total_income", "total_expenses", "profit"}).
			AddRow("0.00", "0.00", "0.00"),
		sqlmock.NewRows([]string{
			"event_id", "title", "event_date", "status",
			"total_income", "total_expenses", "profit",
		}),
		0,
		sqlmock.NewRows([]string{
			"type", "id", "event_id", "event_title", "description", "amount", "created_at",
		}),
	)

	result, err := repository.Get(context.Background(), PeriodAllTime, time.Time{}, time.Time{}, false, 1, DefaultPageSize)
	if err != nil {
		t.Fatal(err)
	}
	if result.TotalIncome != "0.00" || result.TotalExpenses != "0.00" || result.Profit != "0.00" {
		t.Fatalf("unexpected empty-period totals: %+v", result)
	}
	if result.Events == nil || result.Transactions == nil || result.Pagination.TotalPages != 0 {
		t.Fatalf("empty collections must be non-nil and pages zero: %+v", result)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

func TestRepositoryDatabaseFailuresAreReturned(t *testing.T) {
	repository, mock, cleanup := setupRepository(t)
	defer cleanup()
	mock.ExpectBegin()
	mock.ExpectQuery("(?s)WITH income_total AS").
		WithArgs(nil, nil).
		WillReturnError(errors.New("database unavailable"))
	mock.ExpectRollback()

	_, err := repository.Get(context.Background(), PeriodAllTime, time.Time{}, time.Time{}, false, 1, DefaultPageSize)
	if err == nil || !regexp.MustCompile("query finance totals").MatchString(err.Error()) {
		t.Fatalf("expected contextual database error, got %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

func TestServiceValidatesPeriodsDatesAndPagination(t *testing.T) {
	service := NewService(nil)
	service.now = func() time.Time {
		return time.Date(2026, 9, 17, 15, 30, 0, 0, time.FixedZone("local", 5*60*60+30*60))
	}

	tests := []struct {
		name   string
		filter Filter
	}{
		{"unknown period", Filter{Period: "quarter"}},
		{"custom missing start", Filter{Period: PeriodCustom, To: "2026-09-10"}},
		{"invalid custom date", Filter{Period: PeriodCustom, From: "2026-02-30", To: "2026-03-01"}},
		{"reversed custom range", Filter{Period: PeriodCustom, From: "2026-09-02", To: "2026-09-01"}},
		{"date on preset period", Filter{Period: PeriodToday, From: "2026-09-01"}},
		{"page zero", Filter{Period: PeriodToday, Page: -1}},
		{"page excessive", Filter{Period: PeriodToday, Page: MaximumPageNumber + 1}},
		{"page size excessive", Filter{Period: PeriodToday, PageSize: MaximumPageSize + 1}},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			_, err := service.Get(context.Background(), test.filter)
			if !errors.Is(err, ErrInvalidFilter) {
				t.Fatalf("expected ErrInvalidFilter, got %v", err)
			}
		})
	}
}

func TestServiceUsesUtcInclusiveCalendarDateBounds(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	from := time.Date(2026, 9, 1, 0, 0, 0, 0, time.UTC)
	to := time.Date(2026, 10, 1, 0, 0, 0, 0, time.UTC)
	expectReportQueries(
		mock,
		from,
		to,
		DefaultPageSize,
		0,
		sqlmock.NewRows([]string{"total_income", "total_expenses", "profit"}).AddRow("1.00", "0.00", "1.00"),
		sqlmock.NewRows([]string{"event_id", "title", "event_date", "status", "total_income", "total_expenses", "profit"}),
		0,
		sqlmock.NewRows([]string{"type", "id", "event_id", "event_title", "description", "amount", "created_at"}),
	)
	service := NewService(NewRepository(db))
	service.now = func() time.Time { return time.Date(2026, 9, 17, 12, 0, 0, 0, time.UTC) }
	_, err = service.Get(context.Background(), Filter{Period: PeriodCustom, From: "2026-09-01", To: "2026-09-30"})
	if err != nil {
		t.Fatal(err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

func TestServiceResolvesPresetPeriodsAtUtcDateBoundaries(t *testing.T) {
	tests := []struct {
		period       string
		from         time.Time
		toExclusive  time.Time
		expectedFrom string
		expectedTo   string
	}{
		{
			period:       PeriodToday,
			from:         time.Date(2026, 9, 16, 0, 0, 0, 0, time.UTC),
			toExclusive:  time.Date(2026, 9, 17, 0, 0, 0, 0, time.UTC),
			expectedFrom: "2026-09-16",
			expectedTo:   "2026-09-16",
		},
		{
			period:       PeriodThisMonth,
			from:         time.Date(2026, 9, 1, 0, 0, 0, 0, time.UTC),
			toExclusive:  time.Date(2026, 10, 1, 0, 0, 0, 0, time.UTC),
			expectedFrom: "2026-09-01",
			expectedTo:   "2026-09-30",
		},
		{
			period:       PeriodLast30Days,
			from:         time.Date(2026, 8, 18, 0, 0, 0, 0, time.UTC),
			toExclusive:  time.Date(2026, 9, 17, 0, 0, 0, 0, time.UTC),
			expectedFrom: "2026-08-18",
			expectedTo:   "2026-09-16",
		},
	}

	for _, test := range tests {
		t.Run(test.period, func(t *testing.T) {
			db, mock, err := sqlmock.New()
			if err != nil {
				t.Fatal(err)
			}
			defer db.Close()

			expectReportQueries(
				mock,
				test.from,
				test.toExclusive,
				DefaultPageSize,
				0,
				sqlmock.NewRows([]string{"total_income", "total_expenses", "profit"}).
					AddRow("0.00", "0.00", "0.00"),
				sqlmock.NewRows([]string{
					"event_id", "title", "event_date", "status",
					"total_income", "total_expenses", "profit",
				}),
				0,
				sqlmock.NewRows([]string{
					"type", "id", "event_id", "event_title", "description", "amount", "created_at",
				}),
			)

			service := NewService(NewRepository(db))
			service.now = func() time.Time {
				return time.Date(
					2026, 9, 17, 1, 0, 0, 0,
					time.FixedZone("local", 5*60*60+30*60),
				)
			}
			result, err := service.Get(
				context.Background(),
				Filter{Period: test.period},
			)
			if err != nil {
				t.Fatal(err)
			}
			if result.From != test.expectedFrom || result.To != test.expectedTo {
				t.Fatalf("got %s through %s, want %s through %s",
					result.From, result.To, test.expectedFrom, test.expectedTo)
			}
			if err := mock.ExpectationsWereMet(); err != nil {
				t.Fatal(err)
			}
		})
	}
}

func TestHandlerRejectsInvalidQueryAndMapsDatabaseErrors(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	handler := NewHandler(NewService(NewRepository(db)))

	for _, target := range []string{
		"/api/v1/finance/summary?period=unknown",
		"/api/v1/finance/summary?period=custom&from=2026-09-01",
		"/api/v1/finance/summary?page_size=1000",
		"/api/v1/finance/summary?unexpected=true",
		"/api/v1/finance/summary?page=1&page=2",
	} {
		recorder := httptest.NewRecorder()
		handler.Summary(recorder, httptest.NewRequest(http.MethodGet, target, nil))
		if recorder.Code != http.StatusBadRequest {
			t.Errorf("%s returned %d, want 400", target, recorder.Code)
		}
	}

	mock.ExpectBegin()
	mock.ExpectQuery("(?s)WITH income_total AS").
		WithArgs(sqlmock.AnyArg(), sqlmock.AnyArg()).
		WillReturnError(errors.New("database unavailable"))
	mock.ExpectRollback()
	recorder := httptest.NewRecorder()
	handler.Summary(recorder, httptest.NewRequest(http.MethodGet, "/api/v1/finance/summary", nil))
	if recorder.Code != http.StatusInternalServerError {
		t.Fatalf("database error returned %d, want 500", recorder.Code)
	}
}
