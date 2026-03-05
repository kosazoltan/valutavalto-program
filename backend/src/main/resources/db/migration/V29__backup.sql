-- V29: Backup / Restore rendszer
-- Adatbázis mentések nyilvántartása

CREATE TABLE IF NOT EXISTS backup_record (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    backup_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'RUNNING',
    file_path VARCHAR(500),
    file_size_bytes BIGINT,
    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP,
    created_by VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_backup_record_status ON backup_record(status);
CREATE INDEX idx_backup_record_started ON backup_record(started_at DESC);
CREATE INDEX idx_backup_record_type ON backup_record(backup_type);
