# Versioning System

Sadguru Catering OS uses hierarchical engineering versioning.

## Product Generation

`v1.0`

Represents the complete first-generation product.

## Execution Versions

Major execution milestones are represented inside the product generation.

Example:

`v1.1`
`v1.2`
`v1.3`

## Micro Versions

Implementation units use an additional level.

Example:

`v1.1.1`
`v1.1.2`
`v1.1.3`

## Nano Versions

Small implementation, integration, testing, UX or fix tasks may use another level.

Example:

`v1.1.1.1`
`v1.1.1.2`

## Rules

1. A version must represent a defined outcome.
2. A code commit does not automatically create a version.
3. A version must have acceptance criteria.
4. A version must be tested before completion.
5. Completed versions must be documented.
6. Unfinished work must not be silently included in a completed version.
7. New scope must be classified as current-version work, a new micro/nano version, or a future version.
8. Dependencies must be documented before implementation.
9. Production releases must be tagged in Git.
10. The version file must match the active release.

## Example

v1.0
└── v1.0.1
    ├── v1.0.1.1
    ├── v1.0.1.2
    └── v1.0.1.3