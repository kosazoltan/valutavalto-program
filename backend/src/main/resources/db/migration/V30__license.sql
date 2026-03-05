-- V30: Licenc kezelés
-- Szoftver licenc nyilvántartás és validáció

CREATE TABLE IF NOT EXISTS license (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id INTEGER,
    license_key VARCHAR(255) NOT NULL UNIQUE,
    valid_from DATE NOT NULL,
    valid_to DATE NOT NULL,
    max_branches INTEGER NOT NULL DEFAULT 1,
    max_workers INTEGER NOT NULL DEFAULT 5,
    features TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    activated_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_license_company_id ON license(company_id);
CREATE INDEX idx_license_key ON license(license_key);
CREATE INDEX idx_license_is_active ON license(is_active);
