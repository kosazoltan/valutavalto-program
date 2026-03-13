-- V67: Universal Error Logger — error_logs tábla
-- Valutaváltó ERP hibanaplózó rendszer (universal error logger Réteg 1)

CREATE TABLE IF NOT EXISTS error_logs (
    id              VARCHAR(36) PRIMARY KEY,
    fingerprint     VARCHAR(32) NOT NULL UNIQUE,
    error_type      VARCHAR(50) NOT NULL,
    severity        VARCHAR(10) NOT NULL DEFAULT 'ERROR',
    message         TEXT NOT NULL,
    stack           TEXT,
    commit_sha      VARCHAR(40),
    app_name        VARCHAR(50) NOT NULL,
    repo_path       VARCHAR(100) NOT NULL,
    environment     VARCHAR(20) NOT NULL DEFAULT 'production',
    url             VARCHAR(500),
    request_id      VARCHAR(100),
    request_method  VARCHAR(10),
    request_body    TEXT,
    user_id         VARCHAR(100),
    user_email      VARCHAR(200),
    browser         VARCHAR(300),
    occurrence_count INTEGER NOT NULL DEFAULT 1,
    first_seen_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    last_seen_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    email_sent      BOOLEAN NOT NULL DEFAULT false,
    email_sent_at   TIMESTAMP,
    resolved        BOOLEAN NOT NULL DEFAULT false,
    resolved_at     TIMESTAMP,
    resolved_commit VARCHAR(40),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS error_logs_fingerprint_idx ON error_logs(fingerprint);
CREATE INDEX IF NOT EXISTS error_logs_severity_idx    ON error_logs(severity);
CREATE INDEX IF NOT EXISTS error_logs_resolved_idx    ON error_logs(resolved);
CREATE INDEX IF NOT EXISTS error_logs_created_at_idx  ON error_logs(created_at);
