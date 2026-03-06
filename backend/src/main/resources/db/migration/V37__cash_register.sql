-- V37: Pénztárgép (Cash Register) integráció
-- NAV online pénztárgép kötelező a pénzváltóknál (magyar jogszabály)

CREATE TABLE IF NOT EXISTS cash_register_event (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    branch_id UUID NOT NULL REFERENCES branch(id),
    event_type VARCHAR(30) NOT NULL,
    receipt_number VARCHAR(100),
    amount NUMERIC(18, 2),
    currency_code VARCHAR(3),
    amount_huf NUMERIC(18, 2),
    tax_number VARCHAR(20),
    cash_register_id VARCHAR(50),
    event_timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    raw_response TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cash_register_event_branch ON cash_register_event(branch_id);
CREATE INDEX idx_cash_register_event_type ON cash_register_event(event_type);
CREATE INDEX idx_cash_register_event_timestamp ON cash_register_event(event_timestamp);
