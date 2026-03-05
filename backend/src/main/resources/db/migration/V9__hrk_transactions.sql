-- ============================================
-- V9: HRK (Házipénztári Kezelés) tranzakciók
-- Pénztár ↔ Bank közötti pénzmozgás
-- ============================================

CREATE TABLE hrk_transaction (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branch(id) ON DELETE RESTRICT,
    type VARCHAR(20) NOT NULL CHECK (type IN ('HANDOVER', 'RECEIVE')),
    currency_code VARCHAR(3) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    huf_amount DECIMAL(15,2) NOT NULL,
    bank_account_number VARCHAR(50),
    reference VARCHAR(50) NOT NULL,
    note TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'COMPLETED', 'CANCELLED')),
    worker_id BIGINT NOT NULL REFERENCES worker(id) ON DELETE RESTRICT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

CREATE INDEX idx_hrk_transaction_branch ON hrk_transaction(branch_id);
CREATE INDEX idx_hrk_transaction_type ON hrk_transaction(type);
CREATE INDEX idx_hrk_transaction_status ON hrk_transaction(status);
CREATE INDEX idx_hrk_transaction_date ON hrk_transaction(created_at);
CREATE INDEX idx_hrk_transaction_reference ON hrk_transaction(reference);

COMMENT ON TABLE hrk_transaction IS 'Házipénztári kezelés — pénztár és bank közötti pénzmozgás';
