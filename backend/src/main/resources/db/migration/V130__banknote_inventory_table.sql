-- Banknote inventory: denomination-level stock tracking per branch
CREATE TABLE IF NOT EXISTS banknote_inventory (
    id BIGSERIAL PRIMARY KEY,
    branch_id UUID NOT NULL,
    currency_id BIGINT NOT NULL,
    currency_code VARCHAR(3) NOT NULL,
    face_value NUMERIC(19, 4) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0,
    total_value NUMERIC(19, 4),
    min_quantity INTEGER,
    max_quantity INTEGER,
    availability_did VARCHAR(20) DEFAULT 'COMMON',
    last_counted_at TIMESTAMP,
    last_counted_by VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,

    CONSTRAINT uq_inventory_branch_currency_face UNIQUE (branch_id, currency_id, face_value),
    CONSTRAINT chk_inventory_quantity CHECK (quantity >= 0),
    CONSTRAINT chk_inventory_face_value CHECK (face_value > 0),
    CONSTRAINT chk_inventory_availability CHECK (availability_did IN ('COMMON', 'STANDARD', 'RARE', 'OBSOLETE', 'SPECIAL'))
);

CREATE INDEX IF NOT EXISTS idx_inv_branch ON banknote_inventory(branch_id);
CREATE INDEX IF NOT EXISTS idx_inv_branch_currency ON banknote_inventory(branch_id, currency_code);
CREATE INDEX IF NOT EXISTS idx_inv_low_stock ON banknote_inventory(branch_id) WHERE quantity < min_quantity;
