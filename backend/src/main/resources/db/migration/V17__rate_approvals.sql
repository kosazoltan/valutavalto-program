-- V17: Árfolyam engedélyezés (Rate Approval)
-- Legacy: ratectrl.dll — értéktár kontrollálja a pénztárak árfolyamait

CREATE TABLE rate_approval (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id       UUID NOT NULL REFERENCES branch(id),
    currency_code   VARCHAR(3) NOT NULL,
    old_buy_rate    NUMERIC(12, 4),
    old_sell_rate   NUMERIC(12, 4),
    new_buy_rate    NUMERIC(12, 4) NOT NULL,
    new_sell_rate   NUMERIC(12, 4) NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    requested_by    BIGINT REFERENCES worker(id),
    approved_by     BIGINT REFERENCES worker(id),
    requested_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    approved_at     TIMESTAMP,
    reason          VARCHAR(500),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP
);

CREATE INDEX idx_rate_approval_branch ON rate_approval(branch_id);
CREATE INDEX idx_rate_approval_status ON rate_approval(status);
CREATE INDEX idx_rate_approval_requested_at ON rate_approval(requested_at);

-- LED kijelző konfiguráció
CREATE TABLE led_display (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id       UUID NOT NULL REFERENCES branch(id),
    display_type    VARCHAR(30) NOT NULL,
    content         TEXT,
    last_updated    TIMESTAMP NOT NULL DEFAULT NOW(),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_led_display_branch ON led_display(branch_id);

-- Készlet regenerálás napló
CREATE TABLE inventory_regeneration (
    id              BIGSERIAL PRIMARY KEY,
    branch_id       UUID NOT NULL REFERENCES branch(id),
    result_data     TEXT,
    discrepancy_count INT NOT NULL DEFAULT 0,
    corrected_count INT NOT NULL DEFAULT 0,
    regenerated_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    regenerated_by  BIGINT REFERENCES worker(id)
);

CREATE INDEX idx_inv_regen_branch ON inventory_regeneration(branch_id);
