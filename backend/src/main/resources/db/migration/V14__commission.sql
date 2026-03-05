-- V14: Jutalék számítás táblák

-- Jutalék számítás (havi elszámolás)
CREATE TABLE IF NOT EXISTS commission_calculation (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_id           BIGINT NOT NULL,
    branch_id           UUID NOT NULL,
    period              VARCHAR(7) NOT NULL,
    calculation_type    VARCHAR(20) NOT NULL DEFAULT 'MONTHLY',
    total_transactions  INTEGER NOT NULL DEFAULT 0,
    total_volume_huf    DECIMAL(18,2) NOT NULL DEFAULT 0,
    commission_rate     DECIMAL(10,4) DEFAULT 0,
    commission_amount   DECIMAL(18,2) DEFAULT 0,
    bonus_amount        DECIMAL(18,2) DEFAULT 0,
    deductions          DECIMAL(18,2) DEFAULT 0,
    net_commission      DECIMAL(18,2) DEFAULT 0,
    status              VARCHAR(20) NOT NULL DEFAULT 'CALCULATED',
    calculated_at       TIMESTAMP NOT NULL,
    approved_by         BIGINT,
    approved_at         TIMESTAMP,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_comm_calc_worker_period UNIQUE (worker_id, period)
);

CREATE INDEX IF NOT EXISTS idx_comm_calc_branch ON commission_calculation(branch_id);
CREATE INDEX IF NOT EXISTS idx_comm_calc_period ON commission_calculation(period);
CREATE INDEX IF NOT EXISTS idx_comm_calc_status ON commission_calculation(status);

-- Jutalék szabályok (tier-alapú)
CREATE TABLE IF NOT EXISTS commission_rule (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id          INTEGER NOT NULL,
    tier                INTEGER NOT NULL,
    min_volume_huf      DECIMAL(18,2) NOT NULL,
    max_volume_huf      DECIMAL(18,2),
    rate_percent        DECIMAL(10,4) NOT NULL,
    bonus_threshold     DECIMAL(18,2),
    bonus_percent       DECIMAL(10,4) DEFAULT 0,
    valid_from          DATE NOT NULL,
    valid_to            DATE,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_comm_rule_company ON commission_rule(company_id);
CREATE INDEX IF NOT EXISTS idx_comm_rule_tier ON commission_rule(tier);

-- Alapértelmezett jutalék szabályok beszúrása
-- Tier 1: 0-10M HUF → 0.1%
-- Tier 2: 10M-50M HUF → 0.15%
-- Tier 3: 50M+ HUF → 0.2%, bónusz 100M felett +0.05%
INSERT INTO commission_rule (company_id, tier, min_volume_huf, max_volume_huf, rate_percent, bonus_threshold, bonus_percent, valid_from)
SELECT 1, 1, 0, 10000000, 0.10, NULL, 0, '2026-01-01'
WHERE NOT EXISTS (SELECT 1 FROM commission_rule WHERE company_id = 1 AND tier = 1);

INSERT INTO commission_rule (company_id, tier, min_volume_huf, max_volume_huf, rate_percent, bonus_threshold, bonus_percent, valid_from)
SELECT 1, 2, 10000000, 50000000, 0.15, NULL, 0, '2026-01-01'
WHERE NOT EXISTS (SELECT 1 FROM commission_rule WHERE company_id = 1 AND tier = 2);

INSERT INTO commission_rule (company_id, tier, min_volume_huf, max_volume_huf, rate_percent, bonus_threshold, bonus_percent, valid_from)
SELECT 1, 3, 50000000, NULL, 0.20, 100000000, 0.05, '2026-01-01'
WHERE NOT EXISTS (SELECT 1 FROM commission_rule WHERE company_id = 1 AND tier = 3);
