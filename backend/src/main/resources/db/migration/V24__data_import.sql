-- V24: Import felíró (adatimport rendszer)
-- Fiókok adatainak importálása: tranzakciók, készletek, zárások, árfolyamok

CREATE TABLE IF NOT EXISTS data_import_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branch(id),
    import_type VARCHAR(30) NOT NULL,  -- DAILY_CLOSING, INVENTORY, TRANSACTIONS, RATES, FULL
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- PENDING, RUNNING, COMPLETED, FAILED
    source_type VARCHAR(10) NOT NULL DEFAULT 'API',  -- API, FILE, FTP
    source_file VARCHAR(500),
    total_records INTEGER DEFAULT 0,
    imported_records INTEGER DEFAULT 0,
    failed_records INTEGER DEFAULT 0,
    error_log TEXT,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE INDEX idx_data_import_jobs_branch ON data_import_jobs(branch_id);
CREATE INDEX idx_data_import_jobs_status ON data_import_jobs(status);
CREATE INDEX idx_data_import_jobs_type ON data_import_jobs(import_type);
CREATE INDEX idx_data_import_jobs_created ON data_import_jobs(created_at DESC);
