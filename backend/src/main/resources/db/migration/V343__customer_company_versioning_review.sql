-- FS-3 (D2): compliance "Átnézve" workflow — meglévő sorok REVIEWED (terv T4)
ALTER TABLE customer ADD COLUMN IF NOT EXISTS review_status VARCHAR(20) NOT NULL DEFAULT 'REVIEWED';
ALTER TABLE customer ADD COLUMN IF NOT EXISTS reviewed_by VARCHAR(80);
ALTER TABLE customer ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMP;
ALTER TABLE company  ADD COLUMN IF NOT EXISTS review_status VARCHAR(20) NOT NULL DEFAULT 'REVIEWED';
ALTER TABLE company  ADD COLUMN IF NOT EXISTS reviewed_by VARCHAR(80);
ALTER TABLE company  ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_customer_review_status ON customer(company_id, review_status);

-- FS-3 (D1): history snapshotok (terv T1/T2 — jsonb, entitásonkénti tábla)
CREATE TABLE IF NOT EXISTS customer_version (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customer(id),
    company_id UUID NOT NULL,
    version_no BIGINT NOT NULL,
    snapshot JSONB NOT NULL,
    change_source VARCHAR(20) NOT NULL,
    changed_by VARCHAR(80),
    changed_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_customer_version_no UNIQUE (customer_id, version_no)
);
CREATE INDEX IF NOT EXISTS idx_customer_version_company ON customer_version(company_id, customer_id);

CREATE TABLE IF NOT EXISTS company_version (
    id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES company(id),
    version_no BIGINT NOT NULL,
    snapshot JSONB NOT NULL,
    change_source VARCHAR(20) NOT NULL,
    changed_by VARCHAR(80),
    changed_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_company_version_no UNIQUE (company_id, version_no)
);
