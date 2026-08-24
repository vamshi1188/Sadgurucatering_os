# Frontend Structure

The frontend follows a permanent architecture designed to keep application
composition, routing, reusable UI, API communication, shared hooks, utilities,
styles, types, and tests separated by responsibility.

## `app/`

Contains the application shell and root composition, including providers and
top-level application wiring.

## `routes/`

Contains route definitions and route-level components. Business module routes
will be added here rather than scattered across component files.

## `components/`

Contains shared, reusable, presentation-focused UI components. Components
should remain independent of business-domain implementation where practical.

## `api/`

Contains the frontend API client and typed request/response helpers.
HTTP communication is centralized here.

## `hooks/`

Contains shared React hooks used for reusable non-component logic.

## `lib/`

Contains utilities, formatters, constants, and configuration helpers.

## `styles/`

Contains global styles and the Tailwind CSS entry point.

## `types/`

Contains shared TypeScript types and interfaces.

## `test/`

Contains shared test setup and reusable test helpers.

## Architecture Rules

- Components must not access the database.
- Components must not contain duplicated backend business logic.
- API communication must go through the centralized API layer.
- Future business modules must respect these directory responsibilities.
- Business logic must not be introduced during v1.0.4.2.
