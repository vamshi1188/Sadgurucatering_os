package router

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/auth"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/dashboard"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/events"
	"github.com/vamshi1188/Sadgurucatering_os/backend/internal/finance"
	financeReport "github.com/vamshi1188/Sadgurucatering_os/backend/internal/finance/report"
)

func TestFinanceReportRouteRequiresAuthentication(t *testing.T) {
	handler := NewWithFinanceReport(
		auth.New(auth.Config{Password: "test-password", Secret: "test-session-secret"}),
		events.NewHandler(nil),
		finance.NewHandler(nil),
		dashboard.NewHandler(nil),
		financeReport.NewHandler(financeReport.NewService(nil)),
	)

	recorder := httptest.NewRecorder()
	handler.ServeHTTP(
		recorder,
		httptest.NewRequest(http.MethodGet, "/api/v1/finance/summary", nil),
	)
	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf("unauthenticated finance report returned %d, want 401", recorder.Code)
	}
}

func TestFinanceReportAuthenticatedRouteReturnsReportEnvelope(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	authHandler := auth.New(auth.Config{
		Password: "test-password",
		Secret:   "test-session-secret",
	})
	financeReportHandler := financeReport.NewHandler(
		financeReport.NewService(financeReport.NewRepository(db)),
	)
	handler := NewWithFinanceReport(
		authHandler,
		events.NewHandler(nil),
		finance.NewHandler(nil),
		dashboard.NewHandler(nil),
		financeReportHandler,
	)

	login := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/auth/login",
		strings.NewReader(`{"password":"test-password"}`),
	)
	login.Header.Set("Content-Type", "application/json")
	loginRecorder := httptest.NewRecorder()
	handler.ServeHTTP(loginRecorder, login)
	if loginRecorder.Code != http.StatusOK {
		t.Fatalf("login returned %d, want 200", loginRecorder.Code)
	}
	cookies := loginRecorder.Result().Cookies()
	if len(cookies) != 1 {
		t.Fatalf("login returned %d cookies, want one", len(cookies))
	}

	mock.ExpectBegin()
	mock.ExpectQuery("(?s)WITH income_total AS").
		WithArgs(nil, nil).
		WillReturnRows(sqlmock.NewRows([]string{"income", "expenses", "profit"}).
			AddRow("10.10", "3.05", "7.05"))
	mock.ExpectQuery("(?s)WITH income AS").
		WithArgs(nil, nil).
		WillReturnRows(sqlmock.NewRows([]string{
			"event_id", "title", "event_date", "status",
			"total_income", "total_expenses", "profit",
		}))
	mock.ExpectQuery("(?s)SELECT COUNT\\(\\*\\)").
		WithArgs(nil, nil).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(0))
	mock.ExpectQuery("(?s)SELECT\\s+transaction_type").
		WithArgs(nil, nil, financeReport.DefaultPageSize, 0).
		WillReturnRows(sqlmock.NewRows([]string{
			"type", "id", "event_id", "event_title", "description", "amount", "created_at",
		}))
	mock.ExpectCommit()

	request := httptest.NewRequest(
		http.MethodGet,
		"/api/v1/finance/summary?period=all_time",
		nil,
	)
	request.AddCookie(cookies[0])
	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusOK {
		t.Fatalf("finance report returned %d, want 200: %s", recorder.Code, recorder.Body)
	}

	var envelope struct {
		Data struct {
			TotalIncome   string `json:"total_income"`
			TotalExpenses string `json:"total_expenses"`
			Profit        string `json:"profit"`
			Events        []any  `json:"events"`
			Transactions  []any  `json:"transactions"`
		} `json:"data"`
		Meta map[string]any `json:"meta"`
	}
	if err := json.Unmarshal(recorder.Body.Bytes(), &envelope); err != nil {
		t.Fatal(err)
	}
	if envelope.Data.TotalIncome != "10.10" ||
		envelope.Data.TotalExpenses != "3.05" ||
		envelope.Data.Profit != "7.05" {
		t.Fatalf("unexpected report envelope: %+v", envelope.Data)
	}
	if envelope.Data.Events == nil || envelope.Data.Transactions == nil {
		t.Fatal("empty report collections must be encoded as arrays")
	}
	if envelope.Meta == nil {
		t.Fatal("expected response meta envelope")
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}
