-- V96: Add company_id to WU tables for multi-tenant support
-- Note: PostgreSQL does not support ADD COLUMN IF NOT EXISTS, using DO blocks instead.
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'wu_transaction' AND column_name = 'company_id') THEN
        ALTER TABLE wu_transaction ADD COLUMN company_id UUID REFERENCES company(id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'wu_balances' AND column_name = 'company_id') THEN
        ALTER TABLE wu_balances ADD COLUMN company_id UUID REFERENCES company(id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'wu_customers' AND column_name = 'company_id') THEN
        ALTER TABLE wu_customers ADD COLUMN company_id UUID REFERENCES company(id);
    END IF;
END $$;

-- Backfill from branch → company relationship
UPDATE wu_transaction wt SET company_id = b.company_id
FROM branch b WHERE wt.branch_id = b.id AND wt.company_id IS NULL;

UPDATE wu_balances wb SET company_id = b.company_id
FROM branch b WHERE wb.branch_id = b.id AND wb.company_id IS NULL;

-- WuCustomer has no branch_id, backfill from most recent linked transaction
UPDATE wu_customers wc SET company_id = (
    SELECT wt.company_id FROM wu_transaction wt
    WHERE wt.wu_customer_id = wc.id AND wt.company_id IS NOT NULL
    ORDER BY wt.created_at DESC
    LIMIT 1
) WHERE wc.company_id IS NULL;

-- Make NOT NULL after backfill
ALTER TABLE wu_transaction ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE wu_balances ALTER COLUMN company_id SET NOT NULL;
-- wu_customers remains nullable (orphan records possible)

-- Update unique constraint: branch_id alone is not unique in multi-tenant context
ALTER TABLE wu_balances DROP CONSTRAINT IF EXISTS uq_wu_balances_branch;
ALTER TABLE wu_balances ADD CONSTRAINT uq_wu_balances_branch_company UNIQUE (branch_id, company_id);

-- Performance index
CREATE INDEX IF NOT EXISTS idx_wu_balance_branch_company ON wu_balances(branch_id, company_id);
CREATE INDEX IF NOT EXISTS idx_wu_transaction_company ON wu_transaction(company_id);
