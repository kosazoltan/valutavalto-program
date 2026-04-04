-- V138: Napi zárás archiváló táblák (Delphi: CIMTCopy, EdatCopy, KdatCopy, WuniCopy, WzarCopy)
-- S1-02: Értéktár napi zárás teljes workflow

-- 1. Napi címletezés snapshot (Delphi: CIMT{ÉÉVV})
CREATE TABLE IF NOT EXISTS daily_denomination_snapshot (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL,
    snapshot_date DATE NOT NULL,
    currency_code VARCHAR(3) NOT NULL,
    denomination_type VARCHAR(10) NOT NULL,
    face_value NUMERIC(18,2) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0,
    total_value NUMERIC(18,2) NOT NULL DEFAULT 0,
    closing_type INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_denom_snap UNIQUE (branch_id, snapshot_date, currency_code, denomination_type, face_value)
);
CREATE INDEX IF NOT EXISTS idx_denom_snap_branch_date ON daily_denomination_snapshot(branch_id, snapshot_date);
CREATE INDEX IF NOT EXISTS idx_denom_snap_date ON daily_denomination_snapshot(snapshot_date);

COMMENT ON TABLE daily_denomination_snapshot IS 'Napi címletezés snapshot — Delphi CIMTCopy ekvivalens';
COMMENT ON COLUMN daily_denomination_snapshot.closing_type IS '1=esti, 2=kezelési díj, 3=WU, 4=ÁFA, 5=e-kereskedelem';

-- 2. Napi al-pénztár zárás snapshot (Delphi: EDAT/KDAT/WZAR)
CREATE TABLE IF NOT EXISTS daily_subledger_snapshot (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL,
    snapshot_date DATE NOT NULL,
    subledger_type VARCHAR(20) NOT NULL,
    currency_code VARCHAR(3) NOT NULL DEFAULT 'HUF',
    opening_balance NUMERIC(18,2) NOT NULL DEFAULT 0,
    income NUMERIC(18,2) NOT NULL DEFAULT 0,
    expense NUMERIC(18,2) NOT NULL DEFAULT 0,
    closing_balance NUMERIC(18,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_subledger_snap UNIQUE (branch_id, snapshot_date, subledger_type, currency_code)
);
CREATE INDEX IF NOT EXISTS idx_subledger_snap_branch_date ON daily_subledger_snapshot(branch_id, snapshot_date);
CREATE INDEX IF NOT EXISTS idx_subledger_snap_type ON daily_subledger_snapshot(subledger_type);

COMMENT ON TABLE daily_subledger_snapshot IS 'Al-pénztár napi zárás snapshot — Delphi EDAT/KDAT/WZAR ekvivalens';
COMMENT ON COLUMN daily_subledger_snapshot.subledger_type IS 'ECOMMERCE, HANDLING_FEE, WU_USD, WU_HUF, WU_VAT';

-- 3. Napi WU/ÁFA forgalmi tétel archívum (Delphi: WUNI{ÉÉVV})
CREATE TABLE IF NOT EXISTS daily_wu_afa_transaction (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL,
    transaction_date DATE NOT NULL,
    receipt_number VARCHAR(30) NOT NULL,
    currency_code VARCHAR(3) NOT NULL,
    sign VARCHAR(1) NOT NULL,
    amount NUMERIC(18,2) NOT NULL DEFAULT 0,
    receipt_type VARCHAR(10) NOT NULL,
    register_code VARCHAR(10),
    storno INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_wu_afa_tx_branch_date ON daily_wu_afa_transaction(branch_id, transaction_date);
CREATE INDEX IF NOT EXISTS idx_wu_afa_tx_receipt ON daily_wu_afa_transaction(receipt_number);

COMMENT ON TABLE daily_wu_afa_transaction IS 'WU/ÁFA forgalmi snapshot — Delphi WuniCopy ekvivalens';
