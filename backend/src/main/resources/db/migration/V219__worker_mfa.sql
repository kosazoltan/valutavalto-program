-- V219: Worker MFA tábla — Sprint 3 (P2-A — MFA / TOTP)
-- v2.0 spec + Anti masterplan §17

CREATE TABLE IF NOT EXISTS worker_mfa (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_id BIGINT NOT NULL UNIQUE,
    type VARCHAR(20) NOT NULL DEFAULT 'TOTP',
    secret VARCHAR(64) NOT NULL,
    backup_codes_hash TEXT,
    is_enrolled BOOLEAN NOT NULL DEFAULT false,
    is_enabled BOOLEAN NOT NULL DEFAULT false,
    last_verified_at TIMESTAMP,
    last_used_code VARCHAR(10),
    enrolled_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP,
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT chk_worker_mfa_type CHECK (type IN ('TOTP', 'SMS', 'EMAIL'))
);

CREATE INDEX IF NOT EXISTS idx_worker_mfa_worker ON worker_mfa(worker_id);
CREATE INDEX IF NOT EXISTS idx_worker_mfa_enabled ON worker_mfa(is_enabled);
