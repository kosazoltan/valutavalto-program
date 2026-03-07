-- V65: Optimistic locking @Version oszlopok hozzáadása kritikus entity-khez
ALTER TABLE cash_balance ADD COLUMN IF NOT EXISTS version BIGINT DEFAULT 0;
ALTER TABLE transaction ADD COLUMN IF NOT EXISTS version BIGINT DEFAULT 0;
ALTER TABLE transfer ADD COLUMN IF NOT EXISTS version BIGINT DEFAULT 0;
ALTER TABLE exchange_rate ADD COLUMN IF NOT EXISTS version BIGINT DEFAULT 0;
