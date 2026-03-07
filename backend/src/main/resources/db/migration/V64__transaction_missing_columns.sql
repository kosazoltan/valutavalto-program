-- V64: Transaction tábla hiányzó oszlopai
ALTER TABLE transaction
    ADD COLUMN IF NOT EXISTS multi_line BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS line_count INTEGER DEFAULT 1,
    ADD COLUMN IF NOT EXISTS handling_fee_type VARCHAR(20),
    ADD COLUMN IF NOT EXISTS initial_fee DECIMAL(10,0) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS discount_type_code INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS aml_suspicious BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS aml_annual_limit_reached BOOLEAN DEFAULT false;
