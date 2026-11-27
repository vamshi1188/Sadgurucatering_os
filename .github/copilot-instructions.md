# Sadguru Catering OS — Development Rules

These instructions apply to development work throughout this repository. Extend the existing Sadguru Catering OS; do not rebuild functionality that is already present.

## Understand the project first

Before changing code, inspect the repository structure, relevant source and tests, similar features, dependencies, configuration, localization, and documentation. Trace how the requested change connects to the rest of the application. Check whether the required component, service, model, endpoint, utility, or configuration already exists; reuse or extend it before creating anything new.

The repository includes a Go backend (`backend/`), a React and TypeScript frontend (`frontend/`), a Flutter mobile app (`mobile/`), database resources (`database/`), deployments, scripts, tests, and documentation. Follow the architecture and conventions of the affected area rather than introducing a new pattern.

## Preserve architecture and existing behavior

- Keep business logic out of UI components and widgets. Keep authoritative financial calculations in the backend, using decimal-safe representations rather than floating-point arithmetic.
- Reuse existing API clients, endpoints, models, validation, error handling, authentication, authorization, state management, UI components, themes, icons, and localization.
- Preserve API and database compatibility unless the task explicitly requires a change. Follow the existing migration and response conventions.
- Keep changes focused. Do not delete, rename, replace, or restructure existing resources without understanding their dependents and explaining why it is necessary.
- Protect existing dashboard, events, income, expense, finance, settings, authentication, backend API, database migration, web, and Android functionality.
- Provide appropriate loading, empty, success, and error states. For UI work, follow the existing design system, support different screen sizes, and avoid overflow or clipped content.
- Preserve English and Telugu support wherever localization is used; update the existing localization resources rather than hardcoding user-facing strings.

## Dependencies and data safety

Before adding a dependency, check existing packages and whether the language or framework already provides the needed capability. Add a maintained, compatible dependency only when genuinely necessary.

Do not modify production data or run destructive database operations without explicit approval. Preserve transaction auditability and use the repository's existing database migration conventions.

## Tests and validation

Run the smallest relevant checks for the change, and do not claim a check passed unless it was actually run:

- Backend: from `backend/`, run `go test ./...` and `go vet ./...` for backend changes.
- Web frontend: from `frontend/`, use `npm run lint`, `npm test`, and `npm run build` as applicable.
- Flutter: from `mobile/`, use `flutter analyze` and relevant Flutter tests; build the Android APK when the mobile change requires build validation.
- Also run relevant integration or end-to-end tests when the change affects those paths.

Fix regressions caused by the change. Do not make unrelated fixes.

## Git and workflow

1. Inspect `git status` before editing. Treat existing worktree changes as user-owned: do not overwrite, revert, or include unrelated changes.
2. Understand the request and inspect relevant implementations before choosing the minimum change.
3. Implement using established project patterns; update directly related tests and documentation.
4. Format and validate the affected code, then report changed files, behavior, checks actually run, and any remaining limitations.

Do not commit, push, merge, tag, or deploy unless explicitly authorized.
