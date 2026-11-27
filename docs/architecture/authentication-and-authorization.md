# Authentication and authorization

## Architecture

The Go backend is the source of truth for identity and permissions. Users and
sessions are stored in PostgreSQL. Flutter stores the opaque session bearer
token with `flutter_secure_storage` and sends it as
`Authorization: Bearer <token>`. The backend accepts bearer tokens only.

Passwords are hashed with bcrypt before storage. Session tokens are generated
from cryptographically secure random bytes, expire after 24 hours, and are
stored in PostgreSQL only as SHA-256 hashes. The backend resolves the token to
an active user and reads the current role on every protected request. Deleting,
deactivating, or resetting a user's password revokes that user's sessions.
Logout revokes the current token. The mobile app clears the local token and
returns to login after logout or a 401 response.

Login failures use a generic message and are rate limited to five failed
attempts per remote IP/username in a 15-minute window. Passwords must be
12–72 bytes (bcrypt's maximum is 72 bytes). Passwords, bearer tokens, and password hashes must not be logged
or returned by APIs.

## Database

Migration `000006_auth_rbac` adds:

- `users`: case-insensitive unique username, bcrypt `password_hash`, checked
  `role`, active flag, first-login password-change flag, creator reference,
  and timestamps.
- `auth_sessions`: SHA-256 token hash, user foreign key, creation time, and
  expiration time, with user and expiration indexes.
- `user_audit_log`: administrative action, actor and target IDs, details, and
  timestamp. Audit records remain after a user is deleted.

The migration is additive and does not change existing event or finance
records. The backend applies pending migrations at startup. To run migrations
manually from `backend/`, provide `DATABASE_URL` and `MIGRATIONS_PATH` and run
`go run ./cmd/migrate up`. Back up the database before maintenance. The
corresponding down migration drops the user, session, and audit tables and
therefore destroys authentication data; do not run it without explicit
approval.

## Bootstrap administrator

When the backend starts, after migrations, it creates the initial account only
if the `users` table is empty:

- Username: `admin`
- Initial password: `admin123`
- Role: `owner`

The password is bcrypt-hashed, and `must_change_password` is set. Bootstrap
does not recreate users or reset passwords on later starts. The first
successful login is limited to the password-change operation until the
administrator changes the password. Change the initial password immediately;
do not expose it through an API response other than the normal login input or
include it in operational logs.

## Roles and permissions

| Capability | Owner | Supervisor |
|---|---:|---:|
| View dashboard, events, income, expenses, finance, and profitability | Yes | Yes |
| Create, edit, or delete events and financial records | Yes | No |
| List, create, update, deactivate, reset, or delete users | Yes | No |
| Assign owner or supervisor role | Yes | No |
| Change own password | Yes | Yes |

Authorization is enforced by backend middleware and a database-backed user
identity, not by client-supplied role values. Flutter also hides write controls
and owner navigation for supervisors, but that is only a usability layer.
Direct API requests receive `401` when unauthenticated and `403` when the
authenticated role is not permitted.

The last active owner cannot be demoted or deactivated, and cannot be deleted.
The Flutter user-management screen also prevents editing or deleting the
currently signed-in account in ways that could remove its administrative
access. Administrative user changes are recorded in the audit table, and
deactivation, deletion, and password reset revoke the affected user's sessions.

## API endpoints

All paths use the `/api/v1` prefix.

| Method and path | Access | Purpose |
|---|---|---|
| `POST /auth/login` | Public | Username/password login; returns bearer token and public user |
| `GET /auth/session` | Authenticated | Validate the session and return current user |
| `POST /auth/change-password` | Authenticated | Verify current password and change password |
| `POST /auth/logout` | Public with optional token | Revoke supplied token |
| `GET /users` | Owner | List users |
| `POST /users` | Owner | Create owner or supervisor |
| `PATCH /users/{id}` | Owner | Change username, role, or active status |
| `DELETE /users/{id}` | Owner | Delete user and revoke sessions |
| `POST /users/{id}/reset-password` | Owner | Set temporary password and require change at next login |

See [`backend/API_DOCUMENTATION.txt`](../../backend/API_DOCUMENTATION.txt) for
request and response examples and the complete existing business API.

## Deployment and operations

Configure PostgreSQL as for the existing backend. No shared TOML password or
session signing secret is required for authentication; keep only unrelated
application configuration. Use HTTPS between the mobile client and the
backend in production because bearer tokens are sent in the Authorization
header. Protect database backups and audit data with the same care as
credentials. Never run the auth down migration as a routine deployment step.
