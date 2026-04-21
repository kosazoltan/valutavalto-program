-- V155: Optimistic locking (@Version) es hianyzo unique constraint-ek
-- (eredeti V104 a cherry-pick-bol; V104 mar foglalt V104__daily_checklist.sql-ben)

-- 1. @Version oszlopok hozzáadása pénzügyi entitásokhoz
ALTER TABLE daily_session ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;
ALTER TABLE aml_report ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;
ALTER TABLE daily_balance ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;
ALTER TABLE customer ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;

-- 2. Unique constraint: egy nap, egy iroda, egy session
CREATE UNIQUE INDEX IF NOT EXISTS uq_daily_session_branch_date
    ON daily_session (company_id, branch_id, session_date);

-- 3. Unique constraint: bizonylat szám egyediség branch+dátum scope-ban
CREATE UNIQUE INDEX IF NOT EXISTS uq_transaction_receipt_branch_date
    ON transaction (branch_id, transaction_date, receipt_number);
