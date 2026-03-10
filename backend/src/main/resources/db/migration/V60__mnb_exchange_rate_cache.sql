-- V60: MNB hivatalos árfolyam cache tábla
-- A havi záráshoz az MNB SOAP API-ból letöltött napi középárfolyamok.

CREATE TABLE IF NOT EXISTS mnb_exchange_rate_cache (
    id              BIGSERIAL PRIMARY KEY,
    currency_code   VARCHAR(3) NOT NULL,
    rate_date       DATE NOT NULL,
    official_rate   DECIMAL(12,4) NOT NULL,
    unit            INTEGER NOT NULL DEFAULT 1,
    fetched_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_mnb_rate_currency_date UNIQUE (currency_code, rate_date)
);

CREATE INDEX IF NOT EXISTS idx_mnb_rate_date ON mnb_exchange_rate_cache(rate_date);
CREATE INDEX IF NOT EXISTS idx_mnb_rate_currency ON mnb_exchange_rate_cache(currency_code);
