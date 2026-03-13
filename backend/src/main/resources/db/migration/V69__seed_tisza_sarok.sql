-- V69: Tisza Sarok branch seed data
-- Seeds all required dictionary entries + branch + workers
-- Note: Hibernate @GeneratedValue(UUID) does NOT add DEFAULT to DB column, must supply id explicitly

-- Dictionary: Branch Status ACTIVE
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'BRANCH_STATUS', 'ACTIVE', 'Active', 'Aktiv', 1, true, NOW())
ON CONFLICT (category, code) DO NOTHING;

-- Dictionary: Branch Type PENZTAR (penztar iroda)
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'BRANCH_TYPE', 'PENZTAR', 'Cash Office', 'Penztar', 4, true, NOW())
ON CONFLICT (category, code) DO NOTHING;

-- Dictionary: Country HUNGARY
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'COUNTRY', 'HU', 'Hungary', 'Magyarorszag', 1, true, NOW())
ON CONFLICT (category, code) DO NOTHING;

-- Company: Exclusive Best Change Zrt.
INSERT INTO company (id, name, code, is_active, created_at)
VALUES (gen_random_uuid(), 'Exclusive Best Change Zrt.', 'EBC', true, NOW())
ON CONFLICT DO NOTHING;

-- Branch: Tisza Sarok (Szeged)
-- Required NOT NULL dictionary FKs: branch_type_did, country_did, branch_status_did
INSERT INTO branch (id, company_id, name, code, bank_code, city, address, zip_code, opening_date, is_active,
    branch_type_did, country_did, branch_status_did, created_at)
SELECT
    gen_random_uuid(),
    c.id,
    'Tisza Sarok',
    'TISZA',
    'TISZA',
    'Szeged',
    'Tisza Sarok, Szeged',
    '6720',
    CURRENT_DATE,
    true,
    (SELECT id FROM dictionary WHERE category = 'BRANCH_TYPE' AND code = 'PENZTAR'),
    (SELECT id FROM dictionary WHERE category = 'COUNTRY' AND code = 'HU'),
    (SELECT id FROM dictionary WHERE category = 'BRANCH_STATUS' AND code = 'ACTIVE'),
    NOW()
FROM company c WHERE c.code = 'EBC'
ON CONFLICT DO NOTHING;

-- Worker: Borsi Tamas
INSERT INTO worker (id, branch_id, company_id, name, worker_code, email, role, is_active, created_at)
SELECT gen_random_uuid(), b.id, c.id, 'Borsi Tamas', 'BORSI', 'borsi.tamas.ebc@gmail.com', 'CASHIER', true, NOW()
FROM branch b JOIN company c ON b.company_id = c.id WHERE b.code = 'TISZA'
ON CONFLICT DO NOTHING;

-- Worker: Bali Henrietta
INSERT INTO worker (id, branch_id, company_id, name, worker_code, email, role, is_active, created_at)
SELECT gen_random_uuid(), b.id, c.id, 'Bali Henrietta', 'BALI', 'bali.henriett.ebc@gmail.com', 'CASHIER', true, NOW()
FROM branch b JOIN company c ON b.company_id = c.id WHERE b.code = 'TISZA'
ON CONFLICT DO NOTHING;

-- Worker: Kasza Helga
INSERT INTO worker (id, branch_id, company_id, name, worker_code, email, role, is_active, created_at)
SELECT gen_random_uuid(), b.id, c.id, 'Kasza Helga', 'KASZA', 'kasza.helga.ebc@gmail.com', 'CASHIER', true, NOW()
FROM branch b JOIN company c ON b.company_id = c.id WHERE b.code = 'TISZA'
ON CONFLICT DO NOTHING;
