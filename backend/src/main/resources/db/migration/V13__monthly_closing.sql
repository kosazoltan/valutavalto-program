-- V13: Havi zárás tábla
-- A monthly_closing_summary tábla már létezik az alkalmazás korábbi migrációiban.
-- Ez a migráció biztosítja, hogy a struktúra naprakész legyen.

-- Ha még nem létezik, létrehozzuk:
CREATE TABLE IF NOT EXISTS monthly_closing_summary (
    id              BIGSERIAL PRIMARY KEY,
    branch_id       UUID NOT NULL,
    year_month      VARCHAR(7) NOT NULL,
    closed_at       TIMESTAMP NOT NULL,
    closed_by_worker_id BIGINT NOT NULL,
    total_buy_huf   DECIMAL(18,2) NOT NULL DEFAULT 0,
    total_sell_huf  DECIMAL(18,2) NOT NULL DEFAULT 0,
    total_handling_fee DECIMAL(18,2) NOT NULL DEFAULT 0,
    transaction_count INTEGER NOT NULL DEFAULT 0,
    currency_breakdown TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_monthly_closing_branch_month UNIQUE (branch_id, year_month)
);

-- Indexek
CREATE INDEX IF NOT EXISTS idx_monthly_closing_branch ON monthly_closing_summary(branch_id);
CREATE INDEX IF NOT EXISTS idx_monthly_closing_yearmonth ON monthly_closing_summary(year_month);
