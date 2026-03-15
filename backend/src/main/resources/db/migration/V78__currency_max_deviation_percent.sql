-- V78: Add max_deviation_percent column to currency table
-- MNB regulation: certain currencies (e.g. EUA - euro coins) must not deviate
-- more than a configured percentage from the official (middle) exchange rate.

ALTER TABLE currency ADD COLUMN max_deviation_percent NUMERIC(5,2);

COMMENT ON COLUMN currency.max_deviation_percent IS
    'Maximum allowed deviation (%) from official rate. NULL = no limit. MNB regulation.';

-- EUA (euro coin) has a 20% maximum deviation rule per MNB regulation
UPDATE currency SET max_deviation_percent = 20.00 WHERE code = 'EUA';
