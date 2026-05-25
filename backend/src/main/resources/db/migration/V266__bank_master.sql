-- V266: Bank-törzs (FK-005/C1) — a banki átadás-átvétel cél/forrás bankjai.
-- Multi-tenant (company_id) + területi (region_code): a NULL region_code = cég-szintű,
-- minden területen választható; a kitöltött region_code = csak az adott terület értéktárosának.
-- Az N4 (wu_partner_company / V260) mintájára.

CREATE TABLE IF NOT EXISTS bank (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id  UUID NOT NULL REFERENCES company(id),
    name        VARCHAR(200) NOT NULL,
    region_code VARCHAR(10),
    active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bank_company ON bank (company_id);
CREATE INDEX IF NOT EXISTS idx_bank_company_region ON bank (company_id, region_code);
CREATE UNIQUE INDEX IF NOT EXISTS uq_bank_name ON bank (company_id, LOWER(name));

-- Kezdő bank-törzs minden MEGLÉVŐ céghez (cég-szintű, region_code = NULL → minden területen
-- választható). Gyakori magyar bankok; a főértéktáros/vezető bármikor bővítheti vagy területre
-- szűkítheti a POST /api/v1/banks végponton. ON CONFLICT DO NOTHING → idempotens (újra-futtatható).
INSERT INTO bank (company_id, name, region_code, active)
SELECT c.id, b.name, NULL, TRUE
FROM company c
CROSS JOIN (VALUES
    ('OTP Bank'),
    ('Raiffeisen Bank'),
    ('K&H Bank'),
    ('Erste Bank'),
    ('UniCredit Bank'),
    ('MBH Bank'),
    ('CIB Bank'),
    ('Gránit Bank'),
    ('MagNet Bank'),
    ('Magyar Nemzeti Bank')
) AS b(name)
ON CONFLICT DO NOTHING;
