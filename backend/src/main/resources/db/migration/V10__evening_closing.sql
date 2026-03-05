-- ============================================
-- V10: Esti zárás — napi csomag a szervernek
-- ============================================

CREATE TABLE evening_closing (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branch(id) ON DELETE RESTRICT,
    closing_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PREPARING' CHECK (status IN ('PREPARING', 'READY', 'SENT', 'CONFIRMED')),
    package_data JSONB,
    transaction_count INTEGER NOT NULL DEFAULT 0,
    total_buy_huf DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_sell_huf DECIMAL(15,2) NOT NULL DEFAULT 0,
    inventory_snapshot JSONB,
    sent_at TIMESTAMP,
    confirmed_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_evening_closing UNIQUE (branch_id, closing_date)
);

CREATE INDEX idx_evening_closing_branch ON evening_closing(branch_id);
CREATE INDEX idx_evening_closing_date ON evening_closing(closing_date);
CREATE INDEX idx_evening_closing_status ON evening_closing(status);

COMMENT ON TABLE evening_closing IS 'Esti zárás csomag — napi összesítés küldése a szervernek';
