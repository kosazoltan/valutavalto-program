-- ============================================
-- V12: Ügyfélkontroll — tiltások, terrornapló, évi max
-- ============================================

-- Ügyfél korlátozások
CREATE TABLE customer_restriction (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id BIGINT NOT NULL REFERENCES customer(id) ON DELETE CASCADE,
    restriction_type VARCHAR(30) NOT NULL CHECK (restriction_type IN ('BLOCKED', 'SUSPICIOUS', 'WATCH_LIST', 'ANNUAL_LIMIT')),
    reason TEXT NOT NULL,
    added_by BIGINT NOT NULL REFERENCES worker(id) ON DELETE RESTRICT,
    added_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    active BOOLEAN NOT NULL DEFAULT true
);

CREATE INDEX idx_customer_restriction_customer ON customer_restriction(customer_id);
CREATE INDEX idx_customer_restriction_type ON customer_restriction(restriction_type);
CREATE INDEX idx_customer_restriction_active ON customer_restriction(active);

-- Ügyfél szűrés napló (AML / szankciós lista ellenőrzés)
CREATE TABLE customer_screening_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id BIGINT NOT NULL REFERENCES customer(id) ON DELETE CASCADE,
    screening_type VARCHAR(30) NOT NULL CHECK (screening_type IN ('SANCTION', 'AML', 'ANNUAL_CHECK')),
    result VARCHAR(20) NOT NULL CHECK (result IN ('CLEAR', 'FLAGGED', 'BLOCKED')),
    details JSONB,
    screened_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    screened_by BIGINT NOT NULL REFERENCES worker(id) ON DELETE RESTRICT
);

CREATE INDEX idx_screening_log_customer ON customer_screening_log(customer_id);
CREATE INDEX idx_screening_log_type ON customer_screening_log(screening_type);
CREATE INDEX idx_screening_log_result ON customer_screening_log(result);

COMMENT ON TABLE customer_restriction IS 'Ügyfél korlátozások — tiltás, figyelőlista, évi limit';
COMMENT ON TABLE customer_screening_log IS 'Ügyfél szűrés napló — szankciós/AML ellenőrzés eredménye';
