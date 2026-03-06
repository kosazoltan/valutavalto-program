-- V46: Plomba szám nyilvántartás
-- Legacy: GETPLOMB — pénztárnyitás/zárás plomba rögzítés

CREATE TABLE IF NOT EXISTS seal_number (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branch(id),
    seal_number VARCHAR(30) NOT NULL UNIQUE,
    seal_type VARCHAR(20) NOT NULL DEFAULT 'CLOSE',
    session_id UUID,
    worker_id BIGINT,
    note VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    used_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_seal_branch ON seal_number(branch_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_seal_number_unique ON seal_number(seal_number);

-- System paraméterek a kezelési díjhoz (HandlingFeeService-hez)
INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
VALUES
    (gen_random_uuid(), 'HANDLING_FEE_TYPE', 'BRACKET', 'STRING', 'HANDLING_FEE',
     'Kezelési díj típusa: NONE / PER_MILLE / BRACKET', true),
    (gen_random_uuid(), 'HANDLING_FEE_PER_MILLE', '5', 'INTEGER', 'HANDLING_FEE',
     'Ezrelékes kezelési díj (ha típus = PER_MILLE)', true),
    (gen_random_uuid(), 'DAILY_CUSTOM_FEE_LIMIT', '3', 'INTEGER', 'HANDLING_FEE',
     'Napi egyedi kezelési díj limit (pénztárosonként)', true),
    (gen_random_uuid(), 'MAX_BREAK_MINUTES', '15', 'INTEGER', 'BREAK',
     'Maximum szünet idő percben', true)
ON CONFLICT DO NOTHING;
