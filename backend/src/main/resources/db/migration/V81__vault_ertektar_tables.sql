-- V81: Értéktár (vault) modul — begyűjtés és szétosztás kezelés
-- Szükséges a penztar-client Értéktár Dashboard, Collection, Distribution oldalakhoz

CREATE TABLE IF NOT EXISTS vault_collection (
    id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL,
    source_branch_code VARCHAR(10) NOT NULL,
    source_branch_name VARCHAR(100),
    currency_code VARCHAR(3) NOT NULL,
    amount NUMERIC(18,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'REQUESTED',
    requested_at TIMESTAMP NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP,
    note VARCHAR(500),
    requested_by BIGINT
);

CREATE INDEX idx_vault_collection_company ON vault_collection(company_id);
CREATE INDEX idx_vault_collection_status ON vault_collection(company_id, status);
CREATE INDEX idx_vault_collection_branch ON vault_collection(company_id, source_branch_code);

CREATE TABLE IF NOT EXISTS vault_distribution (
    id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'REQUESTED',
    note VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP,
    created_by BIGINT
);

CREATE INDEX idx_vault_distribution_company ON vault_distribution(company_id);
CREATE INDEX idx_vault_distribution_status ON vault_distribution(company_id, status);

CREATE TABLE IF NOT EXISTS vault_distribution_line (
    id BIGSERIAL PRIMARY KEY,
    distribution_id BIGINT NOT NULL REFERENCES vault_distribution(id) ON DELETE CASCADE,
    target_branch_code VARCHAR(10) NOT NULL,
    target_branch_name VARCHAR(100),
    currency_code VARCHAR(3) NOT NULL,
    amount NUMERIC(18,2) NOT NULL
);

CREATE INDEX idx_vault_dist_line_dist ON vault_distribution_line(distribution_id);
