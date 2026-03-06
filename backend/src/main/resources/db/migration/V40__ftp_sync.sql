-- V40: FTP szinkronizáció napló
-- Legacy FTP kompatibilitás — a régi rendszer FTP-vel kommunikált a központtal (port 21100)

CREATE TABLE IF NOT EXISTS ftp_sync_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    branch_id UUID NOT NULL REFERENCES branch(id),
    direction VARCHAR(20) NOT NULL,
    file_name VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'SUCCESS',
    file_size_bytes BIGINT,
    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP,
    error_message TEXT
);

CREATE INDEX idx_ftp_sync_log_branch ON ftp_sync_log(branch_id);
CREATE INDEX idx_ftp_sync_log_status ON ftp_sync_log(status);
CREATE INDEX idx_ftp_sync_log_started ON ftp_sync_log(started_at);
