-- V215: Címletezési optimalizációs stratégiák (Sprint 1 P1-A)
-- v2.0 specifikáció 07_cimletkezeles.md alapján

CREATE TABLE IF NOT EXISTS denomination_optimization (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(500),
    strategy VARCHAR(30) NOT NULL,
    priority_order TEXT,
    min_coins BOOLEAN NOT NULL DEFAULT false,
    min_banknotes BOOLEAN NOT NULL DEFAULT false,
    min_total_count BOOLEAN NOT NULL DEFAULT false,
    is_default BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP,
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT chk_denom_opt_strategy
        CHECK (strategy IN ('GREEDY', 'DYNAMIC', 'MIN_COINS', 'MIN_BANKNOTES', 'MIN_TOTAL', 'CUSTOM', 'BRANCH_SPECIFIC'))
);

CREATE INDEX IF NOT EXISTS idx_denom_opt_default ON denomination_optimization(is_default);
CREATE INDEX IF NOT EXISTS idx_denom_opt_strategy ON denomination_optimization(strategy);

-- Csak 1 alapértelmezett stratégia lehet egyszerre
CREATE UNIQUE INDEX IF NOT EXISTS uq_denom_opt_single_default
    ON denomination_optimization(is_default) WHERE is_default = true;

-- Seed: alapértelmezett 7 stratégia
INSERT INTO denomination_optimization (id, name, description, strategy, is_default, is_active)
VALUES
    (gen_random_uuid(), 'GREEDY default', 'Mohó algoritmus — legnagyobb címletekkel kezdi', 'GREEDY', true, true),
    (gen_random_uuid(), 'DYNAMIC default', 'Dinamikus programozás — minimum darabszámra optimalizál', 'DYNAMIC', false, true),
    (gen_random_uuid(), 'MIN_COINS default', 'Minimum érme kiadás', 'MIN_COINS', false, true),
    (gen_random_uuid(), 'MIN_BANKNOTES default', 'Minimum bankjegy kiadás', 'MIN_BANKNOTES', false, true),
    (gen_random_uuid(), 'MIN_TOTAL default', 'Minimum összes darabszám (érme + bankjegy)', 'MIN_TOTAL', false, true),
    (gen_random_uuid(), 'CUSTOM template', 'Egyedi prioritási sorrend — config JSON-ben', 'CUSTOM', false, true),
    (gen_random_uuid(), 'BRANCH_SPECIFIC template', 'Fiókspecifikus, készlet-aware', 'BRANCH_SPECIFIC', false, true)
ON CONFLICT (name) DO NOTHING;
