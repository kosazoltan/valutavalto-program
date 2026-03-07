-- ============================================================================
-- V60: Értéktári területek + alaptőkék
-- Területi szervezés: pénztárak (branch) területi értéktárakhoz rendelése
-- ============================================================================

CREATE TABLE IF NOT EXISTS vault_territory (
    id SERIAL PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES company(id),
    name VARCHAR(100) NOT NULL,                 -- pl. "Békéscsaba", "Debrecen"
    base_capital DECIMAL(15,2) NOT NULL,        -- alaptőke Ft
    base_capital_approved_at DATE,
    active BOOLEAN DEFAULT true,
    UNIQUE(company_id, name)
);

-- Pénztár (branch) → terület hozzárendelés
ALTER TABLE branch ADD COLUMN IF NOT EXISTS vault_territory_id INT REFERENCES vault_territory(id);

-- Seed: 8 terület
INSERT INTO vault_territory (company_id, name, base_capital, base_capital_approved_at)
SELECT id, 'Békéscsaba', 165000000, '2025-12-15' FROM company LIMIT 1
ON CONFLICT (company_id, name) DO NOTHING;

INSERT INTO vault_territory (company_id, name, base_capital, base_capital_approved_at)
SELECT id, 'Nyíregyháza', 250000000, '2025-12-15' FROM company LIMIT 1
ON CONFLICT (company_id, name) DO NOTHING;

INSERT INTO vault_territory (company_id, name, base_capital, base_capital_approved_at)
SELECT id, 'Szeged', 220000000, '2025-12-15' FROM company LIMIT 1
ON CONFLICT (company_id, name) DO NOTHING;

INSERT INTO vault_territory (company_id, name, base_capital, base_capital_approved_at)
SELECT id, 'Kaposvár', 250000000, '2025-12-15' FROM company LIMIT 1
ON CONFLICT (company_id, name) DO NOTHING;

INSERT INTO vault_territory (company_id, name, base_capital, base_capital_approved_at)
SELECT id, 'Debrecen', 305000000, '2025-12-15' FROM company LIMIT 1
ON CONFLICT (company_id, name) DO NOTHING;

INSERT INTO vault_territory (company_id, name, base_capital, base_capital_approved_at)
SELECT id, 'Kecskemét', 220000000, '2025-12-15' FROM company LIMIT 1
ON CONFLICT (company_id, name) DO NOTHING;

INSERT INTO vault_territory (company_id, name, base_capital, base_capital_approved_at)
SELECT id, 'Pécs', 195000000, '2025-12-15' FROM company LIMIT 1
ON CONFLICT (company_id, name) DO NOTHING;

INSERT INTO vault_territory (company_id, name, base_capital, base_capital_approved_at)
SELECT id, 'Szekszárd', 195000000, '2025-12-15' FROM company LIMIT 1
ON CONFLICT (company_id, name) DO NOTHING;
