-- Password reset tokens are production state, not process memory.
-- Raw tokens are never stored: token_hash = SHA-256(raw reset token).

CREATE TABLE IF NOT EXISTS password_reset_token (
    id BIGSERIAL PRIMARY KEY,
    token_hash VARCHAR(64) NOT NULL UNIQUE,
    worker_id BIGINT NOT NULL REFERENCES worker(id) ON DELETE CASCADE,
    issued_at TIMESTAMP NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_password_reset_worker_active
    ON password_reset_token (worker_id, used_at, expires_at);
