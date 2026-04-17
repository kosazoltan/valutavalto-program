-- V32: Árfolyam történet tábla
-- NOTE: V3 már lefoglalta az idx_rate_history_currency / idx_rate_history_date
-- index-neveket az exchange_rate_history táblán, ezért itt egyedi neveket használunk.
-- Idempotens CREATE TABLE + IF NOT EXISTS a friss lokális DB-re (production baseline=67).
CREATE TABLE IF NOT EXISTS rate_history (
    id              BIGSERIAL PRIMARY KEY,
    currency_code   VARCHAR(3)     NOT NULL,
    buy_rate        DECIMAL(18,6)  NOT NULL,
    sell_rate       DECIMAL(18,6)  NOT NULL,
    mnb_rate        DECIMAL(18,6),
    spread          DECIMAL(10,4),
    category        VARCHAR(20)    NOT NULL DEFAULT 'STANDARD',
    effective_from  TIMESTAMP      NOT NULL,
    effective_to    TIMESTAMP,
    set_by          BIGINT,
    approved_by     BIGINT,
    branch_id       UUID,
    company_id      UUID           NOT NULL,
    created_at      TIMESTAMP      NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rate_history_currency_code ON rate_history(currency_code);
CREATE INDEX IF NOT EXISTS idx_rate_history_effective_dates ON rate_history(effective_from, effective_to);
CREATE INDEX IF NOT EXISTS idx_rate_history_company ON rate_history(company_id);
CREATE INDEX IF NOT EXISTS idx_rate_history_branch ON rate_history(branch_id);
