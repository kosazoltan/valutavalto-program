-- V49: Címlet számlálás + Havi zárás kiegészítő tábla
-- Legacy: CIMLETSZAM + HAVIZARO

CREATE TABLE IF NOT EXISTS denomination_count (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL,
    branch_id UUID NOT NULL REFERENCES branch(id),
    currency_code VARCHAR(3) NOT NULL,
    face_value NUMERIC(15,2) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0,
    count_type VARCHAR(20) NOT NULL DEFAULT 'CLOSING',
    worker_id BIGINT,
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_denom_count_session ON denomination_count(session_id);
CREATE INDEX IF NOT EXISTS idx_denom_count_branch ON denomination_count(branch_id);

CREATE TABLE IF NOT EXISTS monthly_closing (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branch(id),
    year_month VARCHAR(7) NOT NULL,
    total_buy_huf NUMERIC(18,2) DEFAULT 0,
    total_sell_huf NUMERIC(18,2) DEFAULT 0,
    total_profit_huf NUMERIC(18,2) DEFAULT 0,
    transaction_count INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'CLOSED',
    closed_by_id BIGINT,
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_monthly_closing_branch ON monthly_closing(branch_id);
CREATE INDEX IF NOT EXISTS idx_monthly_closing_period ON monthly_closing(year_month);
