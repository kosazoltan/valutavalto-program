-- ============================================================================
-- V59: Értékszállítási bizonylatok (Transfer Documents)
-- Valuta mozgatás nyomon követése: bank→értéktár→pénztár és vissza
-- PIN-alapú biztonsági megerősítéssel
-- ============================================================================

CREATE TABLE IF NOT EXISTS transfer_document (
    id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES company(id),
    document_number VARCHAR(30) NOT NULL,       -- SZ-YYYYMMDD-XXXX

    -- Résztvevők
    sender_id BIGINT NOT NULL REFERENCES worker(id),    -- átadó
    courier_id BIGINT REFERENCES worker(id),            -- szállító (null ha közvetlen)
    receiver_id BIGINT REFERENCES worker(id),           -- átvevő (null amíg nem vette át)

    -- Honnan-hová
    source_type VARCHAR(20) NOT NULL,           -- CASHIER, VAULT, BANK
    source_id VARCHAR(36),                      -- branch_id (UUID) vagy vault_territory_id (int)
    destination_type VARCHAR(20) NOT NULL,
    destination_id VARCHAR(36),

    -- Tartalom
    currency_code VARCHAR(3) NOT NULL,
    quantity DECIMAL(15,2) NOT NULL,
    wac_at_transfer DECIMAL(12,4),              -- WAC a szállítás pillanatában

    -- Státuszok
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    -- PENDING → PICKED_UP → DELIVERED → CONFIRMED

    -- Időbélyegek
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    picked_up_at TIMESTAMP,                     -- értékszállító átvette
    delivered_at TIMESTAMP,                     -- értékszállító átadta
    confirmed_at TIMESTAMP,                     -- átvevő megerősítette

    -- PIN biztonság
    courier_pin_hash VARCHAR(128),              -- értékszállító PIN hash

    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_transfer_doc_status ON transfer_document(status);
CREATE INDEX IF NOT EXISTS idx_transfer_doc_courier ON transfer_document(courier_id, status);
CREATE INDEX IF NOT EXISTS idx_transfer_doc_company ON transfer_document(company_id, created_at);
