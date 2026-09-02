package events

import (
	"context"
	"database/sql"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
)

func TestStatusValid(t *testing.T) {
	tests := []struct {
		name   string
		status Status
		valid  bool
	}{
		{"upcoming", StatusUpcoming, true},
		{"running", StatusRunning, true},
		{"completed", StatusCompleted, true},
		{"invalid", Status("invalid"), false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := tt.status.Valid(); got != tt.valid {
				t.Fatalf("expected %v, got %v", tt.valid, got)
			}
		})
	}
}

func TestValidStatusTransition(t *testing.T) {
	tests := []struct {
		name string
		from Status
		to   Status
		want bool
	}{
		{
			name: "upcoming to running",
			from: StatusUpcoming,
			to:   StatusRunning,
			want: true,
		},
		{
			name: "running to completed",
			from: StatusRunning,
			to:   StatusCompleted,
			want: true,
		},
		{
			name: "upcoming to completed",
			from: StatusUpcoming,
			to:   StatusCompleted,
			want: false,
		},
		{
			name: "running to upcoming",
			from: StatusRunning,
			to:   StatusUpcoming,
			want: false,
		},
		{
			name: "completed to running",
			from: StatusCompleted,
			to:   StatusRunning,
			want: false,
		},
		{
			name: "completed to upcoming",
			from: StatusCompleted,
			to:   StatusUpcoming,
			want: false,
		},
		{
			name: "upcoming to upcoming",
			from: StatusUpcoming,
			to:   StatusUpcoming,
			want: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := validStatusTransition(tt.from, tt.to); got != tt.want {
				t.Fatalf("expected %v, got %v", tt.want, got)
			}
		})
	}
}

func TestServiceUpdateStatusValidTransition(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	service := NewService(NewRepository(db))
	now := time.Now()

	mock.ExpectQuery("SELECT[\\s\\S]*FROM events[\\s\\S]*WHERE id = \\$1").
		WithArgs(int64(1)).
		WillReturnRows(
			sqlmock.NewRows([]string{
				"id",
				"title",
				"event_date",
				"venue",
				"guest_count",
				"status",
				"created_at",
				"updated_at",
			}).AddRow(
				int64(1),
				"Wedding",
				"2026-08-30",
				"Hall",
				100,
				StatusUpcoming,
				now,
				now,
			),
		)

	mock.ExpectQuery("UPDATE events[\\s\\S]*status = \\$2[\\s\\S]*WHERE id = \\$1").
		WithArgs(int64(1), StatusRunning).
		WillReturnRows(
			sqlmock.NewRows([]string{
				"id",
				"title",
				"event_date",
				"venue",
				"guest_count",
				"status",
				"created_at",
				"updated_at",
			}).AddRow(
				int64(1),
				"Wedding",
				"2026-08-30",
				"Hall",
				100,
				StatusRunning,
				now,
				now,
			),
		)

	event, err := service.UpdateStatus(
		context.Background(),
		1,
		StatusRunning,
	)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if event.Status != StatusRunning {
		t.Fatalf("expected status %q, got %q", StatusRunning, event.Status)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("unmet SQL expectations: %v", err)
	}
}

func TestServiceUpdateStatusInvalidTransition(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	service := NewService(NewRepository(db))
	now := time.Now()

	mock.ExpectQuery("SELECT[\\s\\S]*FROM events[\\s\\S]*WHERE id = \\$1").
		WithArgs(int64(1)).
		WillReturnRows(
			sqlmock.NewRows([]string{
				"id",
				"title",
				"event_date",
				"venue",
				"guest_count",
				"status",
				"created_at",
				"updated_at",
			}).AddRow(
				int64(1),
				"Wedding",
				"2026-08-30",
				"Hall",
				100,
				StatusRunning,
				now,
				now,
			),
		)

	_, err = service.UpdateStatus(
		context.Background(),
		1,
		StatusUpcoming,
	)
	if err == nil {
		t.Fatal("expected invalid transition error")
	}

	if !strings.Contains(
		err.Error(),
		"invalid status transition",
	) {
		t.Fatalf("unexpected error: %v", err)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("unmet SQL expectations: %v", err)
	}
}

func TestServiceUpdateStatusNonexistentEvent(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("failed to create sqlmock: %v", err)
	}
	defer db.Close()

	service := NewService(NewRepository(db))

	mock.ExpectQuery("SELECT[\\s\\S]*FROM events[\\s\\S]*WHERE id = \\$1").
		WithArgs(int64(42)).
		WillReturnError(sql.ErrNoRows)

	_, err = service.UpdateStatus(
		context.Background(),
		42,
		StatusRunning,
	)
	if !errors.Is(err, ErrNotFound) {
		t.Fatalf("expected ErrNotFound, got %v", err)
	}

	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatalf("unmet SQL expectations: %v", err)
	}
}

func TestServiceUpdateStatusInvalidStatus(t *testing.T) {
	service := NewService(nil)

	_, err := service.UpdateStatus(
		context.Background(),
		1,
		Status("invalid"),
	)
	if err == nil {
		t.Fatal("expected invalid status error")
	}

	if err.Error() != "status must be one of upcoming, running, completed" {
		t.Fatalf("unexpected error: %v", err)
	}
}
