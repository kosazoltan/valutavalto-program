-- ============================================
-- V11: Zárás kontroll — irodák zárási állapota
-- ============================================

CREATE TABLE closing_control (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branch(id) ON DELETE RESTRICT,
    control_date DATE NOT NULL,
    daily_closing_done BOOLEAN NOT NULL DEFAULT false,
    evening_closing_done BOOLEAN NOT NULL DEFAULT false,
    nav_closing_done BOOLEAN NOT NULL DEFAULT false,
    last_transaction_at TIMESTAMP,
    alert_level VARCHAR(20) NOT NULL DEFAULT 'NONE' CHECK (alert_level IN ('NONE', 'WARNING', 'CRITICAL')),
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_closing_control UNIQUE (branch_id, control_date)
);

CREATE INDEX idx_closing_control_branch ON closing_control(branch_id);
CREATE INDEX idx_closing_control_date ON closing_control(control_date);
CREATE INDEX idx_closing_control_alert ON closing_control(alert_level);

COMMENT ON TABLE closing_control IS 'Zárás kontroll — irodák napi zárási állapotának követése';
