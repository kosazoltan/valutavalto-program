-- V260: Western Union partner-cég törzs (legacy: WUCEGEK / GETWCEG.dll)
-- A WU-ügynöki vállalati partnerek kereshető, multi-tenant nyilvántartása.

CREATE TABLE IF NOT EXISTS wu_partner_company (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id  UUID NOT NULL REFERENCES company(id),
    name        VARCHAR(200) NOT NULL,
    active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_wu_partner_company_company ON wu_partner_company (company_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_wu_partner_company_name
    ON wu_partner_company (company_id, LOWER(name));
