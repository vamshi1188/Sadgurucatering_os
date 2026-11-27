package auth

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
)

const ownerMutationLock int64 = 814723

type SQLRepository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) *SQLRepository {
	return &SQLRepository{db: db}
}

func (repo *SQLRepository) BootstrapOwner(
	ctx context.Context,
	username string,
	password string,
) error {
	username = strings.TrimSpace(username)
	if username == "" {
		return errors.New("bootstrap owner username cannot be empty")
	}
	if password == "" {
		return errors.New("bootstrap owner password cannot be empty")
	}

	tx, err := repo.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if err := lockOwnerMutations(ctx, tx); err != nil {
		return err
	}
	var count int
	if err := tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM users`).Scan(&count); err != nil {
		return err
	}
	if count > 0 {
		return tx.Commit()
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	_, err = tx.ExecContext(ctx, `
		INSERT INTO users (username, password_hash, role, active, must_change_password)
		VALUES ($1, $2, 'owner', TRUE, TRUE)
	`, username, string(hash))
	if err != nil {
		return err
	}
	return tx.Commit()
}

func (repo *SQLRepository) UserByUsername(ctx context.Context, username string) (User, error) {
	return scanUser(repo.db.QueryRowContext(ctx, `
		SELECT id, username, password_hash, role, active, must_change_password, created_at
		FROM users WHERE LOWER(username) = LOWER($1)
	`, username))
}

func (repo *SQLRepository) CreateSession(ctx context.Context, userID int64, tokenHash []byte, expires time.Time, passwordHash string) error {
	if _, err := repo.db.ExecContext(ctx, `DELETE FROM auth_sessions WHERE expires_at <= NOW()`); err != nil {
		return err
	}
	result, err := repo.db.ExecContext(ctx, `
		INSERT INTO auth_sessions (token_hash, user_id, expires_at)
		SELECT $1, id, $3 FROM users
		WHERE id = $2 AND active = TRUE AND password_hash = $4
		FOR UPDATE
	`, tokenHash, userID, expires, passwordHash)
	if err != nil {
		return err
	}
	rows, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

func (repo *SQLRepository) UserForSession(ctx context.Context, tokenHash []byte) (User, error) {
	return scanUser(repo.db.QueryRowContext(ctx, `
		SELECT u.id, u.username, u.password_hash, u.role, u.active, u.must_change_password, u.created_at
		FROM auth_sessions s
		JOIN users u ON u.id = s.user_id
		WHERE s.token_hash = $1 AND s.expires_at > NOW() AND u.active = TRUE
	`, tokenHash))
}

func (repo *SQLRepository) RevokeSession(ctx context.Context, tokenHash []byte) error {
	_, err := repo.db.ExecContext(ctx, `DELETE FROM auth_sessions WHERE token_hash = $1`, tokenHash)
	return err
}

func (repo *SQLRepository) ChangePassword(ctx context.Context, userID int64, passwordHash string, keepSessionHash []byte) error {
	tx, err := repo.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	result, err := tx.ExecContext(ctx, `
		UPDATE users SET password_hash = $1, must_change_password = FALSE, updated_at = NOW()
		WHERE id = $2 AND active = TRUE
	`, passwordHash, userID)
	if err != nil {
		return err
	}
	rows, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return ErrNotFound
	}
	if _, err := tx.ExecContext(ctx, `
		DELETE FROM auth_sessions WHERE user_id = $1 AND token_hash <> $2
	`, userID, keepSessionHash); err != nil {
		return err
	}
	if err := tx.Commit(); err != nil {
		return err
	}
	return nil
}

func (repo *SQLRepository) ListUsers(ctx context.Context) ([]User, error) {
	rows, err := repo.db.QueryContext(ctx, `
		SELECT id, username, password_hash, role, active, must_change_password, created_at
		FROM users ORDER BY id
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	users := make([]User, 0)
	for rows.Next() {
		user, err := scanUser(rows)
		if err != nil {
			return nil, err
		}
		users = append(users, user)
	}
	return users, rows.Err()
}

func (repo *SQLRepository) CreateUser(ctx context.Context, username, role, passwordHash string, actorID int64) (User, error) {
	tx, err := repo.db.BeginTx(ctx, nil)
	if err != nil {
		return User{}, err
	}
	defer tx.Rollback()
	username = strings.ToLower(username)
	var user User
	err = tx.QueryRowContext(ctx, `
		INSERT INTO users (username, password_hash, role, active, must_change_password, created_by)
		VALUES ($1, $2, $3, TRUE, TRUE, $4)
		RETURNING id, username, password_hash, role, active, must_change_password, created_at
	`, username, passwordHash, role, actorID).Scan(&user.ID, &user.Username, &user.PasswordHash, &user.Role, &user.Active, &user.MustChangePassword, &user.CreatedAt)
	if err != nil {
		if isUniqueViolation(err) {
			return User{}, ErrConflict
		}
		return User{}, err
	}
	if err := auditTx(ctx, tx, actorID, user.ID, "user.create", fmt.Sprintf("username=%s role=%s", username, role)); err != nil {
		return User{}, err
	}
	if err := tx.Commit(); err != nil {
		return User{}, err
	}
	return user, nil
}

func (repo *SQLRepository) UpdateUser(ctx context.Context, id int64, username, role *string, active *bool, actorID int64) (User, error) {
	tx, err := repo.db.BeginTx(ctx, nil)
	if err != nil {
		return User{}, err
	}
	defer tx.Rollback()
	if err := lockOwnerMutations(ctx, tx); err != nil {
		return User{}, err
	}
	user, err := scanUser(tx.QueryRowContext(ctx, `
		SELECT id, username, password_hash, role, active, must_change_password, created_at
		FROM users WHERE id = $1 FOR UPDATE
	`, id))
	if errors.Is(err, sql.ErrNoRows) || errors.Is(err, ErrNotFound) {
		return User{}, ErrNotFound
	}
	if err != nil {
		return User{}, err
	}
	nextUsername, nextRole, nextActive := user.Username, user.Role, user.Active
	if username != nil {
		nextUsername = strings.ToLower(*username)
	}
	if role != nil {
		nextRole = *role
	}
	if active != nil {
		nextActive = *active
	}
	if user.Role == "owner" && user.Active && (nextRole != "owner" || !nextActive) {
		var remaining int
		if err := tx.QueryRowContext(ctx, `
			SELECT COUNT(*) FROM users WHERE id <> $1 AND role = 'owner' AND active = TRUE
		`, id).Scan(&remaining); err != nil {
			return User{}, err
		}
		if remaining == 0 {
			return User{}, ErrLastOwner
		}
	}
	updated, err := scanUser(tx.QueryRowContext(ctx, `
		UPDATE users SET username = $1, role = $2, active = $3, updated_at = NOW()
		WHERE id = $4
		RETURNING id, username, password_hash, role, active, must_change_password, created_at
	`, nextUsername, nextRole, nextActive, id))
	if err != nil {
		if isUniqueViolation(err) {
			return User{}, ErrConflict
		}
		return User{}, err
	}
	if !nextActive {
		if _, err := tx.ExecContext(ctx, `DELETE FROM auth_sessions WHERE user_id = $1`, id); err != nil {
			return User{}, err
		}
	}
	if err := auditTx(ctx, tx, actorID, id, "user.update", fmt.Sprintf("username=%s role=%s active=%t", nextUsername, nextRole, nextActive)); err != nil {
		return User{}, err
	}
	if err := tx.Commit(); err != nil {
		return User{}, err
	}
	return updated, nil
}

func (repo *SQLRepository) DeleteUser(ctx context.Context, id, actorID int64) error {
	tx, err := repo.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if err := lockOwnerMutations(ctx, tx); err != nil {
		return err
	}
	user, err := scanUser(tx.QueryRowContext(ctx, `
		SELECT id, username, password_hash, role, active, must_change_password, created_at
		FROM users WHERE id = $1 FOR UPDATE
	`, id))
	if errors.Is(err, sql.ErrNoRows) || errors.Is(err, ErrNotFound) {
		return ErrNotFound
	}
	if err != nil {
		return err
	}
	if user.Role == "owner" && user.Active {
		var remaining int
		if err := tx.QueryRowContext(ctx, `
			SELECT COUNT(*) FROM users WHERE id <> $1 AND role = 'owner' AND active = TRUE
		`, id).Scan(&remaining); err != nil {
			return err
		}
		if remaining == 0 {
			return ErrLastOwner
		}
	}
	if err := auditTx(ctx, tx, actorID, id, "user.delete", ""); err != nil {
		return err
	}
	if _, err := tx.ExecContext(ctx, `DELETE FROM auth_sessions WHERE user_id = $1`, id); err != nil {
		return err
	}
	if _, err := tx.ExecContext(ctx, `DELETE FROM users WHERE id = $1`, id); err != nil {
		return err
	}
	return tx.Commit()
}

func (repo *SQLRepository) ResetPassword(ctx context.Context, id int64, passwordHash string, actorID int64) error {
	tx, err := repo.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	result, err := tx.ExecContext(ctx, `
		UPDATE users SET password_hash = $1, must_change_password = TRUE, updated_at = NOW()
		WHERE id = $2
	`, passwordHash, id)
	if err != nil {
		return err
	}
	rows, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return ErrNotFound
	}
	if err := auditTx(ctx, tx, actorID, id, "user.password_reset", ""); err != nil {
		return err
	}
	if _, err := tx.ExecContext(ctx, `DELETE FROM auth_sessions WHERE user_id = $1`, id); err != nil {
		return err
	}
	return tx.Commit()
}

func auditTx(ctx context.Context, tx *sql.Tx, actorID, targetID int64, action, details string) error {
	_, err := tx.ExecContext(ctx, `
		INSERT INTO user_audit_log (actor_user_id, target_user_id, action, details)
		VALUES ($1, $2, $3, $4)
	`, actorID, targetID, action, details)
	return err
}

func lockOwnerMutations(ctx context.Context, tx *sql.Tx) error {
	var ignored any
	return tx.QueryRowContext(ctx, `SELECT pg_advisory_xact_lock($1)`, ownerMutationLock).Scan(&ignored)
}

type scanner interface {
	Scan(...any) error
}

func scanUser(row scanner) (User, error) {
	var user User
	err := row.Scan(&user.ID, &user.Username, &user.PasswordHash, &user.Role, &user.Active, &user.MustChangePassword, &user.CreatedAt)
	if errors.Is(err, sql.ErrNoRows) {
		return User{}, ErrNotFound
	}
	return user, err
}

func isUniqueViolation(err error) bool {
	var postgresError *pq.Error
	return errors.As(err, &postgresError) && postgresError.Code == "23505"
}
