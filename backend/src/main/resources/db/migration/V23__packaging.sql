-- V23: Göngyöleg kezelés (bankjegy csomagolás nyilvántartás)
CREATE TABLE packaging_record (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id       UUID NOT NULL REFERENCES branch(id),
    currency_code   VARCHAR(3) NOT NULL,
    packaging_date  DATE NOT NULL,
    bundle_count    INTEGER NOT NULL DEFAULT 0,
    denomination    INTEGER NOT NULL,
    bundle_size     INTEGER NOT NULL DEFAULT 100,
    notes           VARCHAR(500),
    created_at      TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_packaging_branch ON packaging_record(branch_id);
CREATE INDEX idx_packaging_date ON packaging_record(packaging_date);
