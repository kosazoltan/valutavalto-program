-- V72: Sync outbox/inbox baseline tables for idempotent edge-central synchronization

CREATE TABLE IF NOT EXISTS sync_outbox (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_type VARCHAR(100) NOT NULL,
    aggregate_id VARCHAR(100) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    idempotency_key VARCHAR(120) NOT NULL UNIQUE,
    payload JSONB NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    retry_count INTEGER NOT NULL DEFAULT 0,
    next_retry_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    sent_at TIMESTAMP,

    CONSTRAINT chk_sync_outbox_status
        CHECK (status IN ('PENDING', 'SENT', 'FAILED', 'DEAD_LETTER'))
);

CREATE INDEX IF NOT EXISTS idx_sync_outbox_status_next_retry
    ON sync_outbox(status, next_retry_at);

CREATE INDEX IF NOT EXISTS idx_sync_outbox_created_at
    ON sync_outbox(created_at);


CREATE TABLE IF NOT EXISTS sync_inbox (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    idempotency_key VARCHAR(120) NOT NULL UNIQUE,
    source_node_id VARCHAR(100) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    payload_hash VARCHAR(128) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'RECEIVED',
    received_at TIMESTAMP NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMP,

    CONSTRAINT chk_sync_inbox_status
        CHECK (status IN ('RECEIVED', 'PROCESSED', 'FAILED', 'DUPLICATE'))
);

CREATE INDEX IF NOT EXISTS idx_sync_inbox_received_at
    ON sync_inbox(received_at);

CREATE INDEX IF NOT EXISTS idx_sync_inbox_status
    ON sync_inbox(status);