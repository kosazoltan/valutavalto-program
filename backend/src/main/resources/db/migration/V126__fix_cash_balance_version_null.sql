-- V126: Fix BUG-001 — cash_balance.version NULL causes Hibernate @Version NPE
-- Set default 0 for existing rows and alter column default

UPDATE cash_balance SET version = 0 WHERE version IS NULL;

ALTER TABLE cash_balance ALTER COLUMN version SET DEFAULT 0;
ALTER TABLE cash_balance ALTER COLUMN version SET NOT NULL;
