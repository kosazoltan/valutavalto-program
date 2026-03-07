-- ============================================================================
-- V58: WAC (Weighted Average Cost) Profit Tracking
-- Valutakészlet nyilvántartás súlyozott átlagár módszerrel
-- + Realizált profit log minden ügyféltranzakciónál
-- ============================================================================

-- Weighted Average Cost nyilvántartás per entitás (pénztár/értéktár) per valutanem
CREATE TABLE IF NOT EXISTS currency_stock (
    id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES company(id),
    entity_type VARCHAR(20) NOT NULL,           -- 'CASHIER' vagy 'VAULT'
    entity_id VARCHAR(36) NOT NULL,             -- branch.id (UUID) vagy vault_territory.id (int as string)
    currency_code VARCHAR(3) NOT NULL,
    quantity DECIMAL(15,2) NOT NULL DEFAULT 0,
    weighted_avg_cost DECIMAL(12,4) NOT NULL DEFAULT 0, -- Ft/egység
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(company_id, entity_type, entity_id, currency_code)
);

-- Profit log: minden ügyféltranzakciónál rögzítjük a realizált hasznot
CREATE TABLE IF NOT EXISTS profit_log (
    id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES company(id),
    transaction_id BIGINT,                      -- FK a transaction táblára
    branch_id UUID NOT NULL,                    -- melyik pénztár (branch.id = UUID)
    currency_code VARCHAR(3) NOT NULL,
    quantity DECIMAL(15,2) NOT NULL,
    acquisition_cost DECIMAL(12,4) NOT NULL,    -- WAC bekerülési ár
    sale_price DECIMAL(12,4) NOT NULL,          -- ügyfél felé ár
    realized_profit DECIMAL(15,2) NOT NULL,     -- (sale_price - acquisition_cost) × quantity
    transaction_type VARCHAR(10) NOT NULL,       -- 'SELL' vagy 'BUY'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_currency_stock_entity ON currency_stock(entity_type, entity_id, currency_code);
CREATE INDEX IF NOT EXISTS idx_profit_log_branch ON profit_log(branch_id, created_at);
CREATE INDEX IF NOT EXISTS idx_profit_log_company ON profit_log(company_id, created_at);
