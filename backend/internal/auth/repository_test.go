package auth

import (
	"context"
	"database/sql"
	"database/sql/driver"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
	"golang.org/x/crypto/bcrypt"
)

func TestBootstrapDoesNotReplaceExistingUsers(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	repo := NewRepository(db)

	mock.ExpectBegin()
	mock.ExpectQuery("SELECT pg_advisory_xact_lock").
		WithArgs(ownerMutationLock).
		WillReturnRows(sqlmock.NewRows([]string{"pg_advisory_xact_lock"}).AddRow(nil))
	mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM users").
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))
	mock.ExpectCommit()

	if err := repo.BootstrapOwner(context.Background(), "admin", "admin123"); err != nil {
		t.Fatalf("bootstrap failed: %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

func TestBootstrapCreatesOwnerWhenNoUsersExist(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	repo := NewRepository(db)

	mock.ExpectBegin()
	mock.ExpectQuery("SELECT pg_advisory_xact_lock").
		WithArgs(ownerMutationLock).
		WillReturnRows(sqlmock.NewRows([]string{"pg_advisory_xact_lock"}).AddRow(nil))
	mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM users").
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(0))
	mock.ExpectExec("INSERT INTO users").
		WithArgs("owner-initial", passwordHashMatcher{password: "bootstrap-password"}).
		WillReturnResult(sqlmock.NewResult(1, 1))
	mock.ExpectCommit()

	if err := repo.BootstrapOwner(
		context.Background(),
		"owner-initial",
		"bootstrap-password",
	); err != nil {
		t.Fatalf("bootstrap failed: %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

type passwordHashMatcher struct {
	password string
}

func (matcher passwordHashMatcher) Match(value driver.Value) bool {
	hash, ok := value.(string)
	if !ok {
		return false
	}
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(matcher.password)) == nil
}

func TestUpdateCannotDemoteLastActiveOwner(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	repo := NewRepository(db)
	role := "supervisor"

	mock.ExpectBegin()
	mock.ExpectQuery("SELECT pg_advisory_xact_lock").
		WithArgs(ownerMutationLock).
		WillReturnRows(sqlmock.NewRows([]string{"pg_advisory_xact_lock"}).AddRow(nil))
	mock.ExpectQuery("SELECT id, username, password_hash, role, active, must_change_password").
		WithArgs(int64(1)).
		WillReturnRows(sqlmock.NewRows([]string{
			"id", "username", "password_hash", "role", "active", "must_change_password", "created_at",
		}).AddRow(1, "owner", "hash", "owner", true, false, time.Now()))
	mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM users").
		WithArgs(int64(1)).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(0))
	mock.ExpectRollback()

	_, err = repo.UpdateUser(context.Background(), 1, nil, &role, nil, 1)
	if !errors.Is(err, ErrLastOwner) {
		t.Fatalf("expected ErrLastOwner, got %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

func TestDeleteCannotDeleteLastActiveOwner(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	repo := NewRepository(db)

	mock.ExpectBegin()
	mock.ExpectQuery("SELECT pg_advisory_xact_lock").
		WithArgs(ownerMutationLock).
		WillReturnRows(sqlmock.NewRows([]string{"pg_advisory_xact_lock"}).AddRow(nil))
	mock.ExpectQuery("SELECT id, username, password_hash, role, active, must_change_password").
		WithArgs(int64(1)).
		WillReturnRows(sqlmock.NewRows([]string{
			"id", "username", "password_hash", "role", "active", "must_change_password", "created_at",
		}).AddRow(1, "owner", "hash", "owner", true, false, time.Now()))
	mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM users").
		WithArgs(int64(1)).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(0))
	mock.ExpectRollback()

	err = repo.DeleteUser(context.Background(), 1, 1)
	if !errors.Is(err, ErrLastOwner) {
		t.Fatalf("expected ErrLastOwner, got %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

func TestSessionInsertRequiresUnchangedActivePassword(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	repo := NewRepository(db)
	tokenHash := []byte("hash")
	expires := time.Now().Add(time.Hour)

	mock.ExpectExec("DELETE FROM auth_sessions WHERE expires_at").
		WillReturnResult(sqlmock.NewResult(0, 0))
	mock.ExpectExec("INSERT INTO auth_sessions").
		WithArgs(tokenHash, int64(7), expires, "password-hash").
		WillReturnResult(sqlmock.NewResult(0, 0))

	err = repo.CreateSession(context.Background(), 7, tokenHash, expires, "password-hash")
	if !errors.Is(err, ErrNotFound) {
		t.Fatalf("expected stale login session to be rejected, got %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

func TestCreateUserRecordsCreator(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	repo := NewRepository(db)

	mock.ExpectBegin()
	mock.ExpectQuery("INSERT INTO users").
		WithArgs("supervisor-one", "password-hash", "supervisor", int64(9)).
		WillReturnRows(sqlmock.NewRows([]string{
			"id", "username", "password_hash", "role", "active", "must_change_password", "created_at",
		}).AddRow(15, "supervisor-one", "password-hash", "supervisor", true, true, time.Now()))
	mock.ExpectExec("INSERT INTO user_audit_log").
		WithArgs(int64(9), int64(15), "user.create", "username=supervisor-one role=supervisor").
		WillReturnResult(sqlmock.NewResult(1, 1))
	mock.ExpectCommit()

	user, err := repo.CreateUser(context.Background(), "supervisor-one", "supervisor", "password-hash", 9)
	if err != nil {
		t.Fatalf("create user failed: %v", err)
	}
	if user.ID != 15 || user.Role != "supervisor" {
		t.Fatalf("unexpected created user: %+v", user)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

func TestResetPasswordRevokesSessionsAndAuditsTransactionally(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	repo := NewRepository(db)

	mock.ExpectBegin()
	mock.ExpectExec("UPDATE users SET password_hash").
		WithArgs("new-hash", int64(4)).
		WillReturnResult(sqlmock.NewResult(0, 1))
	mock.ExpectExec("INSERT INTO user_audit_log").
		WithArgs(int64(2), int64(4), "user.password_reset", "").
		WillReturnResult(sqlmock.NewResult(1, 1))
	mock.ExpectExec("DELETE FROM auth_sessions WHERE user_id").
		WithArgs(int64(4)).
		WillReturnResult(sqlmock.NewResult(0, 2))
	mock.ExpectCommit()

	if err := repo.ResetPassword(context.Background(), 4, "new-hash", 2); err != nil {
		t.Fatalf("reset password failed: %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

func TestExpiredDatabaseSessionIsUnauthorizedBySessionAPI(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	handler := New(NewRepository(db))
	token, tokenHash, err := newToken()
	if err != nil {
		t.Fatal(err)
	}

	mock.ExpectQuery("s.expires_at > NOW\\(\\) AND u.active = TRUE").
		WithArgs(tokenHash).
		WillReturnError(sql.ErrNoRows)

	request := httptest.NewRequest(http.MethodGet, "/api/v1/auth/session", nil)
	request.Header.Set("Authorization", "Bearer "+token)
	recorder := httptest.NewRecorder()

	handler.Session(recorder, request)

	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf("expired session returned %d, want 401", recorder.Code)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}
