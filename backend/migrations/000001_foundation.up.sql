CREATE TABLE schema_metadata (
    id BIGSERIAL PRIMARY KEY,
    schema_version INTEGER NOT NULL,
    application_version VARCHAR(32) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
