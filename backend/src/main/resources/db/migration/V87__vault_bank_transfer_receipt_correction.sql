-- V87: Értéktári banki tranzakciók, értéktárközi áttételek, anyagbevételi bizonylatok, készletkorrekciók
-- Legacy MATPTAR, ATADVET, MATBIZONYLAT, KESZEDIT megfelelők

-- 1. Banki tranzakciók (MATPTAR — anyagpénztári banki vétel/eladás)
CREATE TABLE IF NOT EXISTS vault_bank_transaction (
    id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL,
    vault_territory_id INTEGER REFERENCES vault_territory(id),
    transaction_type VARCHAR(10) NOT NULL CHECK (transaction_type IN ('BUY', 'SELL')),
    currency_code VARCHAR(3) NOT NULL,
    amount NUMERIC(18,2) NOT NULL,
    exchange_rate NUMERIC(12,4) NOT NULL,
    huf_amount NUMERIC(18,2) NOT NULL,
    bank_name VARCHAR(100),
    bank_reference VARCHAR(100),
    status VARCHAR(20) NOT NULL DEFAULT 'REQUESTED',
    note VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP,
    created_by BIGINT,
    approved_by BIGINT
);

CREATE INDEX idx_vault_bank_tx_company ON vault_bank_transaction(company_id);
CREATE INDEX idx_vault_bank_tx_status ON vault_bank_transaction(company_id, status);
CREATE INDEX idx_vault_bank_tx_type ON vault_bank_transaction(company_id, transaction_type);
CREATE INDEX idx_vault_bank_tx_date ON vault_bank_transaction(company_id, created_at);

-- 2. Értéktárközi / irodaközi áttételek (ATADVET — átadás-vétel)
CREATE TABLE IF NOT EXISTS vault_transfer (
    id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL,
    transfer_number VARCHAR(30) NOT NULL,
    source_vault_id INTEGER REFERENCES vault_territory(id),
    target_vault_id INTEGER REFERENCES vault_territory(id),
    source_branch_code VARCHAR(10),
    target_branch_code VARCHAR(10),
    currency_code VARCHAR(3) NOT NULL,
    amount NUMERIC(18,2) NOT NULL,
    wac_at_transfer NUMERIC(12,4),
    status VARCHAR(20) NOT NULL DEFAULT 'REQUESTED',
    requires_supervisor BOOLEAN NOT NULL DEFAULT FALSE,
    supervisor_approved_by BIGINT,
    supervisor_approved_at TIMESTAMP,
    note VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP,
    created_by BIGINT,
    received_by BIGINT,
    received_at TIMESTAMP,

    CONSTRAINT chk_vault_transfer_direction CHECK (
        (source_vault_id IS NOT NULL OR source_branch_code IS NOT NULL)
        AND (target_vault_id IS NOT NULL OR target_branch_code IS NOT NULL)
    )
);

CREATE INDEX idx_vault_transfer_company ON vault_transfer(company_id);
CREATE INDEX idx_vault_transfer_status ON vault_transfer(company_id, status);
CREATE INDEX idx_vault_transfer_number ON vault_transfer(company_id, transfer_number);
CREATE INDEX idx_vault_transfer_date ON vault_transfer(company_id, created_at);

-- 3. Anyag bevételi / kiadási bizonylatok (MATBIZONYLAT — B=bevétel, K=kiadás)
CREATE TABLE IF NOT EXISTS material_receipt (
    id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL,
    receipt_number VARCHAR(30) NOT NULL,
    receipt_type VARCHAR(1) NOT NULL CHECK (receipt_type IN ('B', 'K')),
    vault_territory_id INTEGER REFERENCES vault_territory(id),
    branch_code VARCHAR(10),
    counterpart_name VARCHAR(200),
    note VARCHAR(500),
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    finalized_at TIMESTAMP,
    created_by BIGINT
);

CREATE INDEX idx_material_receipt_company ON material_receipt(company_id);
CREATE INDEX idx_material_receipt_number ON material_receipt(company_id, receipt_number);
CREATE INDEX idx_material_receipt_type ON material_receipt(company_id, receipt_type);

-- Bizonylat tételsorok
CREATE TABLE IF NOT EXISTS material_receipt_line (
    id BIGSERIAL PRIMARY KEY,
    receipt_id BIGINT NOT NULL REFERENCES material_receipt(id) ON DELETE CASCADE,
    currency_code VARCHAR(3) NOT NULL,
    amount NUMERIC(18,2) NOT NULL,
    exchange_rate NUMERIC(12,4),
    huf_equivalent NUMERIC(18,2)
);

CREATE INDEX idx_material_receipt_line_receipt ON material_receipt_line(receipt_id);

-- 4. Készletkorrekciók (KESZEDIT — leltárkülönbözet rendezés)
CREATE TABLE IF NOT EXISTS stock_correction (
    id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL,
    entity_type VARCHAR(20) NOT NULL,
    entity_id VARCHAR(36) NOT NULL,
    currency_code VARCHAR(3) NOT NULL,
    old_quantity NUMERIC(18,2) NOT NULL,
    new_quantity NUMERIC(18,2) NOT NULL,
    difference NUMERIC(18,2) NOT NULL,
    reason VARCHAR(500) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'REQUESTED',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    approved_at TIMESTAMP,
    created_by BIGINT,
    approved_by BIGINT
);

CREATE INDEX idx_stock_correction_company ON stock_correction(company_id);
CREATE INDEX idx_stock_correction_entity ON stock_correction(company_id, entity_type, entity_id);

-- Szekvencia a bizonylat számokhoz
CREATE SEQUENCE IF NOT EXISTS vault_transfer_seq START 1;
CREATE SEQUENCE IF NOT EXISTS material_receipt_seq START 1;
