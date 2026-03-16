-- V96: Add company_id to WU tables for multi-tenant support
ALTER TABLE wu_transaction ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES company(id);
ALTER TABLE wu_balance ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES company(id);
ALTER TABLE wu_customer ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES company(id);

-- Backfill from branch → company relationship
UPDATE wu_transaction wt SET company_id = b.company_id
FROM branch b WHERE wt.branch_id = b.id AND wt.company_id IS NULL;

UPDATE wu_balance wb SET company_id = b.company_id
FROM branch b WHERE wb.branch_id = b.id AND wb.company_id IS NULL;

-- WuCustomer has no branch_id, backfill from first linked transaction
UPDATE wu_customer wc SET company_id = (
    SELECT DISTINCT wt.company_id FROM wu_transaction wt
    WHERE wt.wu_customer_id = wc.id AND wt.company_id IS NOT NULL
    LIMIT 1
) WHERE wc.company_id IS NULL;

-- Make NOT NULL after backfill
ALTER TABLE wu_transaction ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE wu_balance ALTER COLUMN company_id SET NOT NULL;
-- wu_customer remains nullable (orphan records possible)

-- Performance index
CREATE INDEX IF NOT EXISTS idx_wu_balance_branch_company ON wu_balance(branch_id, company_id);
CREATE INDEX IF NOT EXISTS idx_wu_transaction_company ON wu_transaction(company_id);
