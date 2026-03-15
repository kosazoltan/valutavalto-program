-- V82: Dekád haszon — MNB árfolyamos készletfelértékelés sorok
-- A dekádjelentéshez valutánkénti bontás: nyitó/záró készlet × MNB árfolyam

-- Dekád haszon összesítő mezők a meglévő táblához
ALTER TABLE decade_report
    ADD COLUMN IF NOT EXISTS opening_inventory_value_huf NUMERIC(18,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS closing_inventory_value_huf NUMERIC(18,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS decade_profit_huf NUMERIC(18,2) DEFAULT 0;

-- Valutánkénti bontás tábla
CREATE TABLE IF NOT EXISTS decade_report_line (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    decade_report_id UUID NOT NULL REFERENCES decade_report(id) ON DELETE CASCADE,
    currency_code   VARCHAR(3) NOT NULL,

    -- Nyitó készlet (dekád első napja)
    opening_balance     NUMERIC(18,4) NOT NULL DEFAULT 0,
    opening_mnb_rate    NUMERIC(12,4),
    opening_value_huf   NUMERIC(18,2) NOT NULL DEFAULT 0,

    -- Záró készlet (dekád utolsó napja)
    closing_balance     NUMERIC(18,4) NOT NULL DEFAULT 0,
    closing_mnb_rate    NUMERIC(12,4),
    closing_value_huf   NUMERIC(18,2) NOT NULL DEFAULT 0,

    -- Különbség = dekád haszon az adott valutára
    profit_huf          NUMERIC(18,2) NOT NULL DEFAULT 0,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT uk_decade_line_report_currency UNIQUE (decade_report_id, currency_code)
);

CREATE INDEX IF NOT EXISTS idx_decade_line_report ON decade_report_line(decade_report_id);
