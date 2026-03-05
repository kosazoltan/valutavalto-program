-- V28: Fiók státusz monitoring (locserver)
-- Központi szerver figyeli az alárendelt fiókok állapotát

CREATE TABLE IF NOT EXISTS branch_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL UNIQUE,
    last_heartbeat TIMESTAMP,
    last_sync TIMESTAMP,
    is_online BOOLEAN NOT NULL DEFAULT false,
    last_transaction_at TIMESTAMP,
    daily_transaction_count INTEGER NOT NULL DEFAULT 0,
    daily_volume_huf NUMERIC(18,2) NOT NULL DEFAULT 0,
    open_alerts INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_branch_status_branch_id ON branch_status(branch_id);
CREATE INDEX idx_branch_status_is_online ON branch_status(is_online);
CREATE INDEX idx_branch_status_last_heartbeat ON branch_status(last_heartbeat);
