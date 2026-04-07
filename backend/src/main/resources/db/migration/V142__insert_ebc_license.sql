-- V100: EBC cég licenc aktiválás (P0-6 fix — LicenseService kényszerítés)
-- A LicenseService.validateLicense() NO_LICENSE-t ad ha nincs rekord
INSERT INTO license (id, company_id, license_key, valid_from, valid_to, max_branches, max_workers, features, is_active, activated_at, created_at, updated_at)
SELECT
    gen_random_uuid(),
    1,
    'EBC-PROD-' || encode(gen_random_bytes(16), 'hex'),
    '2026-01-01',
    '2027-12-31',
    10,
    50,
    '["WU","HRK","STAMPS","DARIUS","CAMERA","AML","NAV","POS"]',
    true,
    NOW(),
    NOW(),
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM license WHERE is_active = true);
