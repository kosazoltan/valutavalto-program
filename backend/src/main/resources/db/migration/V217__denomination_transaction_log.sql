-- V217: Címletezési döntés napló (Sprint 1 P2-E)
-- v2.0 specifikáció 07_cimletkezeles.md alapján

CREATE TABLE IF NOT EXISTS denomination_transaction_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id BIGINT NOT NULL,
    worker_id BIGINT NOT NULL,
    branch_id UUID NOT NULL,
    strategy VARCHAR(30) NOT NULL,
    rule_id UUID,
    huf_amount NUMERIC(15, 2),
    suggested_breakdown TEXT,
    accepted_breakdown TEXT,
    decision VARCHAR(20) NOT NULL,
    notes VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    CONSTRAINT chk_denom_txlog_strategy
        CHECK (strategy IN ('GREEDY', 'DYNAMIC', 'MIN_COINS', 'MIN_BANKNOTES', 'MIN_TOTAL', 'CUSTOM', 'BRANCH_SPECIFIC')),
    CONSTRAINT chk_denom_txlog_decision
        CHECK (decision IN ('ACCEPTED', 'MODIFIED', 'OVERRIDDEN', 'INSUFFICIENT'))
);

CREATE INDEX IF NOT EXISTS idx_denom_txlog_transaction ON denomination_transaction_log(transaction_id);
CREATE INDEX IF NOT EXISTS idx_denom_txlog_strategy ON denomination_transaction_log(strategy);
CREATE INDEX IF NOT EXISTS idx_denom_txlog_decision ON denomination_transaction_log(decision);
CREATE INDEX IF NOT EXISTS idx_denom_txlog_branch_date ON denomination_transaction_log(branch_id, created_at);
