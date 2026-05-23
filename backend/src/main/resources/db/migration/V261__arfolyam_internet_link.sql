-- V261: Árfolyamkészítő internet-link (legacy ARFOLYAM / TINTERNETTMKFORM, Unit2.pas)
-- A rate-maker Főlapján gyors-megnyitható internet-linkek: {egyedi gombszám, felirat, URL}.
-- Multi-tenant, a gombszám cégen belül egyedi (legacy: "X SZÁMÚ GOMB MÁR KI VAN OSZTVA").

CREATE TABLE IF NOT EXISTS arfolyam_internet_link (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id    UUID NOT NULL REFERENCES company(id),
    button_number INTEGER NOT NULL,
    label         VARCHAR(100) NOT NULL,
    url           VARCHAR(500) NOT NULL,
    created_at    TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_arf_internet_link_company ON arfolyam_internet_link (company_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_arf_internet_link_number
    ON arfolyam_internet_link (company_id, button_number);
