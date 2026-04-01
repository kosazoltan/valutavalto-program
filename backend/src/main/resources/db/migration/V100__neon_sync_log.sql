-- Neon DB szinkronizáció állapot-napló tábla
CREATE TABLE IF NOT EXISTS neon_sync_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sync_started_at TIMESTAMP NOT NULL,
    sync_finished_at TIMESTAMP,
    table_name      VARCHAR(100),
    records_synced  INTEGER DEFAULT 0,
    status          VARCHAR(20) NOT NULL DEFAULT 'RUNNING',
    error_message   TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_neon_sync_log_status ON neon_sync_log(status);
CREATE INDEX idx_neon_sync_log_started ON neon_sync_log(sync_started_at DESC);
CREATE INDEX idx_neon_sync_log_watermark ON neon_sync_log(table_name, status, sync_finished_at DESC);
