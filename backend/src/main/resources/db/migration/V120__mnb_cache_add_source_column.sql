-- V120: source oszlop hozzáadása az mnb_exchange_rate_cache táblához
-- Raiffeisen devizaközép integráció — megkülönböztetni MNB vs RAIFFEISEN forrást.
ALTER TABLE mnb_exchange_rate_cache
    ADD COLUMN IF NOT EXISTS source VARCHAR(20) NOT NULL DEFAULT 'MNB';

-- Unique constraint frissítés: source is a kulcs része
-- Prod DB constraint neve: ukukodymsn5g7gg50go7yyuvba (JPA generált)
ALTER TABLE mnb_exchange_rate_cache
    DROP CONSTRAINT IF EXISTS ukukodymsn5g7gg50go7yyuvba;
ALTER TABLE mnb_exchange_rate_cache
    DROP CONSTRAINT IF EXISTS mnb_exchange_rate_cache_currency_code_rate_date_key;
ALTER TABLE mnb_exchange_rate_cache
    ADD CONSTRAINT mnb_exchange_rate_cache_currency_code_rate_date_source_key
    UNIQUE (currency_code, rate_date, source);
