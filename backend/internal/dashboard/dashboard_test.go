package dashboard

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
)

func TestRepositorySummaryAggregatesDateRangeAndKeepsEvents(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	mock.ExpectQuery("SELECT COUNT\\(\\*\\)").WithArgs("2026-09-01", "2026-09-02").WillReturnRows(
		sqlmock.NewRows([]string{"event_count", "upcoming_count", "running_count", "completed_count", "total_income", "total_expenses", "profit"}).AddRow(2, 1, 1, 0, "70000.00", "25000.00", "45000.00"),
	)
	mock.ExpectQuery("SELECT e.id, e.title").WithArgs("2026-09-01", "2026-09-02").WillReturnRows(
		sqlmock.NewRows([]string{"id", "title", "event_date", "venue", "guest_count", "status", "total_income", "total_expenses", "profit"}).
			AddRow(1, "Event A", "2026-09-01", "Hall A", 500, "upcoming", "50000.00", "18000.00", "32000.00").
			AddRow(2, "Event B", "2026-09-02", "Hall B", 150, "running", "20000.00", "7000.00", "13000.00"),
	)

	result, err := NewRepository(db).Summary(context.Background(), "2026-09-01", "2026-09-02")
	if err != nil {
		t.Fatal(err)
	}
	if result.EventCount != 2 || result.TotalIncome != "70000.00" || result.TotalExpenses != "25000.00" || result.Profit != "45000.00" {
		t.Fatalf("unexpected summary: %+v", result)
	}
	if len(result.Events) != 2 || result.Events[0].Title != "Event A" || result.Events[1].Title != "Event B" {
		t.Fatalf("expected individually identifiable events, got %+v", result.Events)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

func TestServiceRejectsInvalidDateRange(t *testing.T) {
	_, err := NewService(nil).Summary(context.Background(), "2026-09-03", "2026-09-02")
	if err == nil || err.Error() != "invalid date range" {
		t.Fatalf("expected invalid date range, got %v", err)
	}
}

func TestHandlerReturnsSummaryAndRejectsInvalidDates(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	mock.ExpectQuery("SELECT COUNT\\(\\*\\)").WithArgs("2026-09-01", "2026-09-01").WillReturnRows(
		sqlmock.NewRows([]string{"event_count", "upcoming_count", "running_count", "completed_count", "total_income", "total_expenses", "profit"}).AddRow(0, 0, 0, 0, "0.00", "0.00", "0.00"),
	)
	mock.ExpectQuery("SELECT e.id, e.title").WithArgs("2026-09-01", "2026-09-01").WillReturnRows(
		sqlmock.NewRows([]string{"id", "title", "event_date", "venue", "guest_count", "status", "total_income", "total_expenses", "profit"}),
	)

	handler := NewHandler(NewService(NewRepository(db)))
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/dashboard/summary?from=2026-09-01&to=2026-09-01", nil)
	handler.Summary(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rec.Code)
	}
	var body struct {
		Data Summary `json:"data"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil || body.Data.EventCount != 0 {
		t.Fatalf("unexpected response: %s", rec.Body.String())
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}

	rec = httptest.NewRecorder()
	handler.Summary(rec, httptest.NewRequest(http.MethodGet, "/api/v1/dashboard/summary?from=bad", nil))
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for invalid date, got %d", rec.Code)
	}
}
