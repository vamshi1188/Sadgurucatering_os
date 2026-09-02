CREATE TABLE events (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    event_date DATE NOT NULL,
    venue VARCHAR(255) NOT NULL,
    guest_count INTEGER NOT NULL CHECK (guest_count >= 0),
    status VARCHAR(16) NOT NULL DEFAULT 'upcoming'
        CHECK (status IN ('upcoming', 'running', 'completed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_events_event_date
    ON events(event_date);

CREATE INDEX idx_events_status
    ON events(status);

CREATE INDEX idx_events_event_date_status
    ON events(event_date, status);
