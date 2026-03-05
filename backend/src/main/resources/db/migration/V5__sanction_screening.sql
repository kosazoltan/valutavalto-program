-- V5: Szankciós szűrés — ENSZ/EU/OFAC lista
-- Jogszabályi kötelezettség: Pmt. 2017. évi LIII. tv.

-- Szankciós lista bejegyzések
CREATE TABLE IF NOT EXISTS sanction_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(500) NOT NULL,
    aliases TEXT,
    date_of_birth VARCHAR(50),
    nationality VARCHAR(100),
    document_number VARCHAR(100),
    list_type VARCHAR(20) NOT NULL,
    list_reference VARCHAR(500),
    added_date DATE,
    last_updated DATE,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sanction_full_name ON sanction_entries (full_name);
CREATE INDEX IF NOT EXISTS idx_sanction_document_number ON sanction_entries (document_number);
CREATE INDEX IF NOT EXISTS idx_sanction_active ON sanction_entries (active);
CREATE INDEX IF NOT EXISTS idx_sanction_list_type ON sanction_entries (list_type);

-- Szűrés audit napló (ki, mikor, kit szűrt, mi volt az eredmény)
CREATE TABLE IF NOT EXISTS sanction_screening_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    screened_name VARCHAR(500) NOT NULL,
    screened_document_number VARCHAR(100),
    screened_date_of_birth VARCHAR(50),
    result VARCHAR(20) NOT NULL,
    match_count INTEGER NOT NULL DEFAULT 0,
    match_details TEXT,
    worker_id VARCHAR(50),
    worker_name VARCHAR(200),
    branch_code VARCHAR(20),
    supervisor_approved BOOLEAN DEFAULT FALSE,
    supervisor_name VARCHAR(200),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_screening_log_screened_name ON sanction_screening_log (screened_name);
CREATE INDEX IF NOT EXISTS idx_screening_log_result ON sanction_screening_log (result);
CREATE INDEX IF NOT EXISTS idx_screening_log_created ON sanction_screening_log (created_at);
CREATE INDEX IF NOT EXISTS idx_screening_log_worker ON sanction_screening_log (worker_id);
