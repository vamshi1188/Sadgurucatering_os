CREATE INDEX idx_event_income_created_at
    ON event_income(created_at DESC, id DESC);

CREATE INDEX idx_event_expenses_created_at
    ON event_expenses(created_at DESC, id DESC);
