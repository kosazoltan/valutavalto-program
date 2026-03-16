-- V86: Fix NULL version in exchange_rate table
-- JPA @Version requires non-null value for optimistic locking.
-- Seed data (V76) did not set version, causing NullPointerException on update.
UPDATE exchange_rate SET version = 0 WHERE version IS NULL;
ALTER TABLE exchange_rate ALTER COLUMN version SET DEFAULT 0;
ALTER TABLE exchange_rate ALTER COLUMN version SET NOT NULL;
