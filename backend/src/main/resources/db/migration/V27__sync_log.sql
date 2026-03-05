-- V27: Sync log tábla — szinkronizáció naplózás
CREATE TABLE sync_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id       UUID NOT NULL REFERENCES branch(id),
    sync_type       VARCHAR(20) NOT NULL,
    direction       VARCHAR(10) NOT NULL DEFAULT 'DOWN',
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    started_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    completed_at    TIMESTAMP,
    record_count    INTEGER DEFAULT 0,
    error_message   TEXT,

    CONSTRAINT chk_sync_type CHECK (sync_type IN ('RATES','TRANSACTIONS','INVENTORY','CLOSING','FULL')),
    CONSTRAINT chk_sync_direction CHECK (direction IN ('UP','DOWN')),
    CONSTRAINT chk_sync_status CHECK (status IN ('PENDING','RUNNING','COMPLETED','FAILED'))
);

CREATE INDEX idx_sync_log_branch ON sync_log(branch_id);
CREATE INDEX idx_sync_log_status ON sync_log(status);
CREATE INDEX idx_sync_log_started_at ON sync_log(started_at);
