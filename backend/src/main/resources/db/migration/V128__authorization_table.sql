-- V128: Authorization tábla — meghatalmazás jogosultságok
-- "authorization" is a PostgreSQL reserved word — must be quoted
CREATE TABLE IF NOT EXISTS "authorization" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    representative_id UUID NOT NULL REFERENCES authorized_representative(id),
    operation_did VARCHAR(50) NOT NULL,
    authorization_type_did VARCHAR(50),
    status_did VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    start_date DATE NOT NULL,
    expiry_date DATE,
    single_transaction_limit NUMERIC(15,0),
    max_amount NUMERIC(15,0),
    max_transaction_count INTEGER,
    used_transaction_count INTEGER NOT NULL DEFAULT 0,
    used_amount NUMERIC(15,0) NOT NULL DEFAULT 0,
    notes VARCHAR(500),
    status_reason VARCHAR(500),
    verified_by_worker_id BIGINT,
    verified_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP
);

ALTER TABLE "authorization" ADD CONSTRAINT chk_authorization_status
    CHECK (status_did IN ('PENDING', 'ACTIVE', 'SUSPENDED', 'REVOKED'));

ALTER TABLE "authorization" ADD CONSTRAINT chk_authorization_dates
    CHECK (expiry_date IS NULL OR expiry_date >= start_date);

CREATE INDEX IF NOT EXISTS idx_authorization_representative ON "authorization"(representative_id);
CREATE INDEX IF NOT EXISTS idx_authorization_status ON "authorization"(status_did);
