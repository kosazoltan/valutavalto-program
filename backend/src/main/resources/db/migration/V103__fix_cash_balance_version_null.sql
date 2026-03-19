-- V103: Fix NULL version in cash_balance table
-- JPA @Version requires non-null value for optimistic locking.
-- Existing seeded or legacy-updated rows with NULL version can crash daily opening on save.
UPDATE cash_balance SET version = 0 WHERE version IS NULL;
ALTER TABLE cash_balance ALTER COLUMN version SET DEFAULT 0;
ALTER TABLE cash_balance ALTER COLUMN version SET NOT NULL;