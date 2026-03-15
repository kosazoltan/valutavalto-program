-- V77: Fix V4 FK type mismatches
-- V4 created several tables with UUID columns referencing BIGINT/BIGSERIAL PKs.
-- These tables were likely never used in production (no entity classes), but the
-- FK constraints are invalid if the referenced table has a different PK type.
-- Fix: drop broken FKs and recreate columns with correct types.

-- bank_cash_journal: currency_id UUID→BIGINT, worker_id UUID→BIGINT
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'bank_cash_journal') THEN
        -- Drop existing data (no entity = no production data)
        ALTER TABLE bank_cash_journal DROP CONSTRAINT IF EXISTS bank_cash_journal_currency_id_fkey;
        ALTER TABLE bank_cash_journal DROP CONSTRAINT IF EXISTS bank_cash_journal_worker_id_fkey;

        -- Fix currency_id: UUID → BIGINT
        ALTER TABLE bank_cash_journal ALTER COLUMN currency_id TYPE BIGINT USING NULL;
        ALTER TABLE bank_cash_journal ADD CONSTRAINT bank_cash_journal_currency_id_fkey
            FOREIGN KEY (currency_id) REFERENCES currency(id);

        -- Fix worker_id: UUID → BIGINT
        ALTER TABLE bank_cash_journal ALTER COLUMN worker_id TYPE BIGINT USING NULL;
        ALTER TABLE bank_cash_journal ADD CONSTRAINT bank_cash_journal_worker_id_fkey
            FOREIGN KEY (worker_id) REFERENCES worker(id);
    END IF;
END $$;

-- decade_reports: printed_by UUID → BIGINT
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'decade_reports') THEN
        ALTER TABLE decade_reports DROP CONSTRAINT IF EXISTS decade_reports_printed_by_fkey;
        ALTER TABLE decade_reports ALTER COLUMN printed_by TYPE BIGINT USING NULL;
        ALTER TABLE decade_reports ADD CONSTRAINT decade_reports_printed_by_fkey
            FOREIGN KEY (printed_by) REFERENCES worker(id);
    END IF;
END $$;

-- stamp_receipts: worker_id UUID → BIGINT
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'stamp_receipts') THEN
        ALTER TABLE stamp_receipts DROP CONSTRAINT IF EXISTS stamp_receipts_worker_id_fkey;
        ALTER TABLE stamp_receipts ALTER COLUMN worker_id TYPE BIGINT USING NULL;
        ALTER TABLE stamp_receipts ADD CONSTRAINT stamp_receipts_worker_id_fkey
            FOREIGN KEY (worker_id) REFERENCES worker(id);
    END IF;
END $$;

-- wu_transactions: worker_id UUID → BIGINT
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'wu_transactions') THEN
        ALTER TABLE wu_transactions DROP CONSTRAINT IF EXISTS wu_transactions_worker_id_fkey;
        ALTER TABLE wu_transactions ALTER COLUMN worker_id TYPE BIGINT USING NULL;
        ALTER TABLE wu_transactions ADD CONSTRAINT wu_transactions_worker_id_fkey
            FOREIGN KEY (worker_id) REFERENCES worker(id);
    END IF;
END $$;

-- wu_customers: customer_id UUID → BIGINT (customer.id is BIGSERIAL)
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'wu_customers') THEN
        ALTER TABLE wu_customers DROP CONSTRAINT IF EXISTS wu_customers_customer_id_fkey;
        ALTER TABLE wu_customers ALTER COLUMN customer_id TYPE BIGINT USING NULL;
        ALTER TABLE wu_customers ADD CONSTRAINT wu_customers_customer_id_fkey
            FOREIGN KEY (customer_id) REFERENCES customer(id);
    END IF;
END $$;
