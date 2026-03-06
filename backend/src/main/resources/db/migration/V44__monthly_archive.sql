-- V42: Havi gyűjtő / archiválás rendszer
-- 
-- A Delphi rendszer havonta archiválta a tranzakciókat (BLOKKFEJ → BFéévhh, stb.)
-- Modern megközelítés: központi archived_transactions tábla időbélyeggel

CREATE TABLE archived_transactions (
    id BIGSERIAL PRIMARY KEY,
    
    -- Archivum azonosító (YYYY-MM formátum: "2026-03")
    archive_month VARCHAR(7) NOT NULL,
    
    -- Eredeti tranzakció adatok
    original_id BIGINT NOT NULL,
    receipt_number VARCHAR(20),
    transaction_type VARCHAR(30),
    currency_code VARCHAR(3),
    amount DECIMAL(18,2),
    exchange_rate DECIMAL(18,6),
    huf_amount DECIMAL(18,2),
    handling_fee DECIMAL(18,2),
    rounding_amount DECIMAL(18,2),
    original_date TIMESTAMP,
    
    -- Branch és munkatárs azonosítók
    branch_id UUID,
    worker_id BIGINT,
    
    -- Ügyfél információ (AML követés)
    customer_name VARCHAR(200),
    customer_id VARCHAR(50),
    document_number VARCHAR(50),
    
    -- Metaadat
    archived_at TIMESTAMP DEFAULT NOW(),
    archived_by VARCHAR(100),
    
    -- Multi-tenant
    company_id UUID,
    
    -- Státusz (ARCHIVED = lezárt, nem törölhető)
    archive_status VARCHAR(20) DEFAULT 'ARCHIVED'
);

-- Indexek gyors kereséshez
CREATE INDEX idx_archived_month ON archived_transactions(archive_month);
CREATE INDEX idx_archived_branch ON archived_transactions(branch_id, archive_month);
CREATE INDEX idx_archived_original ON archived_transactions(original_id);
CREATE INDEX idx_archived_date ON archived_transactions(original_date);
CREATE INDEX idx_archived_company ON archived_transactions(company_id, archive_month);

-- Audit log bővítés archiválási eseményekhez
COMMENT ON TABLE archived_transactions IS 'Havi archivált tranzakciók – Delphi CopyTables megfelelő (modern verzió)';
COMMENT ON COLUMN archived_transactions.archive_month IS 'Archivum hónap YYYY-MM formátumban';
COMMENT ON COLUMN archived_transactions.original_id IS 'Eredeti transaction tábla ID';
COMMENT ON COLUMN archived_transactions.archive_status IS 'ARCHIVED = lezárt, nem törölhető';
