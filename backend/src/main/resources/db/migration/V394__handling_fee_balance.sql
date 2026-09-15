-- FKH-071: branch-scoped rolled HUF balance of uncollected handling fees.
-- Starts at 0 (no historical backfill). Unique (company_id, branch_id).

CREATE TABLE IF NOT EXISTS handling_fee_balance (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    company_id UUID NOT NULL,
    branch_id UUID NOT NULL,
    current_balance NUMERIC(18,2) NOT NULL DEFAULT 0,
    version BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_hfb_balance_nonnegative CHECK (current_balance >= 0),
    CONSTRAINT ux_hfb_company_branch UNIQUE (company_id, branch_id)
);
