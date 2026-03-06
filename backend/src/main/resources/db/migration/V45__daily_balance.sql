-- V43: Napi készlet / forgalom tábla
--
-- A Delphi napi záráskor számolta a készletmozgást (nyitó, vétel, átvétel, eladás, átadás, záró)
-- Ez a számviteli lánc alapja, nélkülözhetetlen a havi záráshoz

CREATE TABLE daily_balance (
    id BIGSERIAL PRIMARY KEY,
    
    -- Iroda és dátum
    branch_id UUID NOT NULL,
    balance_date DATE NOT NULL,
    
    -- Valuta
    currency_code VARCHAR(3) NOT NULL,
    
    -- Készletmozgás
    opening_balance DECIMAL(18,2) NOT NULL DEFAULT 0.00,  -- nyitó (előző nap záró)
    purchases DECIMAL(18,2) NOT NULL DEFAULT 0.00,        -- vásárlás (beérkezett valuta)
    transfers_in DECIMAL(18,2) NOT NULL DEFAULT 0.00,     -- átvétel más irodától
    sales DECIMAL(18,2) NOT NULL DEFAULT 0.00,            -- eladás (kiadott valuta)
    transfers_out DECIMAL(18,2) NOT NULL DEFAULT 0.00,    -- átadás más irodába
    closing_balance DECIMAL(18,2) NOT NULL DEFAULT 0.00,  -- záró = nyitó + vétel + átvétel - eladás - átadás
    
    -- Tényleges készlet (leltár alapján)
    actual_stock DECIMAL(18,2),                           -- tényleges leltár
    difference DECIMAL(18,2),                             -- eltérés = záró - tényleges
    
    -- Metaadat
    created_at TIMESTAMP DEFAULT NOW(),
    closed_by VARCHAR(100),
    
    -- Multi-tenant
    company_id UUID NOT NULL,
    
    -- Lezárás státusza
    is_closed BOOLEAN DEFAULT FALSE,
    closed_at TIMESTAMP,
    
    -- Megjegyzés eltérés esetén
    difference_note TEXT,
    
    CONSTRAINT uq_daily_balance_branch_date_currency UNIQUE (branch_id, balance_date, currency_code, company_id)
);

-- Indexek
CREATE INDEX idx_daily_balance_branch_date ON daily_balance(branch_id, balance_date);
CREATE INDEX idx_daily_balance_date ON daily_balance(balance_date);
CREATE INDEX idx_daily_balance_currency ON daily_balance(currency_code);
CREATE INDEX idx_daily_balance_company ON daily_balance(company_id, balance_date);

-- Kommentek
COMMENT ON TABLE daily_balance IS 'Napi készletmozgás — Delphi napi forgalom számítás megfelelő';
COMMENT ON COLUMN daily_balance.opening_balance IS 'Nyitó készlet (előző nap záró)';
COMMENT ON COLUMN daily_balance.closing_balance IS 'Záró készlet = nyitó + vétel + átvétel - eladás - átadás';
COMMENT ON COLUMN daily_balance.actual_stock IS 'Tényleges leltári készlet (ha van leltár)';
COMMENT ON COLUMN daily_balance.difference IS 'Eltérés = záró számított - tényleges leltár';
