-- V216: Címletezési szabályok (Sprint 1 P1-B)
-- v2.0 specifikáció 07_cimletkezeles.md alapján

CREATE TABLE IF NOT EXISTS denomination_rule (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_name VARCHAR(150) NOT NULL UNIQUE,
    currency_id BIGINT,
    rule_type VARCHAR(30) NOT NULL,
    min_amount NUMERIC(15, 2),
    max_amount NUMERIC(15, 2),
    branch_id UUID,
    optimization_id UUID NOT NULL,
    rule_config TEXT,
    priority INTEGER NOT NULL DEFAULT 100,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP,
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT fk_denom_rule_optimization FOREIGN KEY (optimization_id)
        REFERENCES denomination_optimization(id),
    CONSTRAINT chk_denom_rule_type
        CHECK (rule_type IN ('FIXED', 'AMOUNT_BASED', 'CUSTOMER_TYPE', 'TRANSACTION_TYPE',
                              'BRANCH_DEFAULT', 'TIME_BASED', 'AVAILABILITY', 'PRIORITY')),
    CONSTRAINT chk_denom_rule_amount_range
        CHECK (min_amount IS NULL OR max_amount IS NULL OR min_amount <= max_amount)
);

CREATE INDEX IF NOT EXISTS idx_denom_rule_branch ON denomination_rule(branch_id);
CREATE INDEX IF NOT EXISTS idx_denom_rule_type ON denomination_rule(rule_type);
CREATE INDEX IF NOT EXISTS idx_denom_rule_currency ON denomination_rule(currency_id);
CREATE INDEX IF NOT EXISTS idx_denom_rule_active_priority ON denomination_rule(is_active, priority);

-- Seed: rendszerszintű FIXED alapszabály (GREEDY-vel)
INSERT INTO denomination_rule (id, rule_name, rule_type, optimization_id, priority, is_active)
SELECT gen_random_uuid(), 'Rendszer alapértelmezett (FIXED + GREEDY)', 'FIXED', do.id, 999, true
FROM denomination_optimization do
WHERE do.name = 'GREEDY default' AND do.is_default = true
ON CONFLICT (rule_name) DO NOTHING;
