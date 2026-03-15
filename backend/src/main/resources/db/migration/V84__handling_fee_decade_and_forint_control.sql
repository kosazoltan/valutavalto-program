-- =============================================================================
-- V84: Kezelési díj dekád összesítő + Forint kontroll tábla
-- Legacy: KEZDEKAD.DLL + DEKRUTIN.DLL
-- =============================================================================

-- 1. Kezelési díj dekád összesítő (KEZDEKAD)
CREATE TABLE IF NOT EXISTS handling_fee_decade_report (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branch(id),
    year INTEGER NOT NULL,
    decade INTEGER NOT NULL,  -- 1-36
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,

    -- Nyitó egyenleg (előző dekád záró)
    opening_balance NUMERIC(18,2) NOT NULL DEFAULT 0,

    -- Összesített díjak
    total_buy_fee NUMERIC(18,2) NOT NULL DEFAULT 0,      -- Vételi kezelési díj
    total_sell_fee NUMERIC(18,2) NOT NULL DEFAULT 0,      -- Eladási kezelési díj
    total_card_fee NUMERIC(18,2) NOT NULL DEFAULT 0,      -- Bankkártyás díj (elkülönítve)
    total_cash_fee NUMERIC(18,2) NOT NULL DEFAULT 0,      -- Készpénzes díj

    -- Záró egyenleg
    closing_balance NUMERIC(18,2) NOT NULL DEFAULT 0,

    -- Sorszámozás (KEZDIJSORSZAM)
    first_sequence_number INTEGER,
    last_sequence_number INTEGER,

    -- Tranzakciós adatok
    buy_count INTEGER NOT NULL DEFAULT 0,
    sell_count INTEGER NOT NULL DEFAULT 0,
    total_count INTEGER NOT NULL DEFAULT 0,

    -- Státusz
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    printed BOOLEAN NOT NULL DEFAULT FALSE,
    closed_at TIMESTAMP,
    closed_by BIGINT,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP,

    CONSTRAINT uk_hf_decade_branch_year_decade UNIQUE (branch_id, year, decade)
);

CREATE INDEX IF NOT EXISTS idx_hf_decade_branch ON handling_fee_decade_report(branch_id);
CREATE INDEX IF NOT EXISTS idx_hf_decade_year ON handling_fee_decade_report(year);

-- 2. Forint kontroll (DEKRUTIN — dekád forint egyenleg validáció)
-- Ez a decade_report-hoz ad forint kontroll mezőket
ALTER TABLE decade_report
    ADD COLUMN IF NOT EXISTS forint_opening NUMERIC(18,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS forint_total_income NUMERIC(18,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS forint_total_expense NUMERIC(18,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS forint_closing NUMERIC(18,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS forint_control_valid BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS forint_control_diff NUMERIC(18,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS first_receipt_number VARCHAR(20),
    ADD COLUMN IF NOT EXISTS last_receipt_number VARCHAR(20),
    ADD COLUMN IF NOT EXISTS card_payment_total NUMERIC(18,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS print_control_flag BOOLEAN DEFAULT FALSE;
