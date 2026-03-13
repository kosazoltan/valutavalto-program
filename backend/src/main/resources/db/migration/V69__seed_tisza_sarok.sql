-- V69: Tisza Sarok branch seed data
-- Seeds all required dictionary entries + branch + workers
-- Worker.id = BIGSERIAL (auto), Worker columns: code, password_hash, role, active (not is_active)

-- Dictionary: Branch Status ACTIVE
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'BRANCH_STATUS', 'ACTIVE', 'Active', 'Aktiv', 1, true, NOW())
ON CONFLICT (category, code) DO NOTHING;

-- Dictionary: Branch Type PENZTAR
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'BRANCH_TYPE', 'PENZTAR', 'Cash Office', 'Penztar', 4, true, NOW())
ON CONFLICT (category, code) DO NOTHING;

-- Dictionary: Country Hungary
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'COUNTRY', 'HU', 'Hungary', 'Magyarorszag', 1, true, NOW())
ON CONFLICT (category, code) DO NOTHING;

-- Company: Exclusive Best Change Zrt.
INSERT INTO company (id, name, code, is_active, created_at)
VALUES (gen_random_uuid(), 'Exclusive Best Change Zrt.', 'EBC', true, NOW())
ON CONFLICT DO NOTHING;

-- Branch: Tisza Sarok (Szeged)
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

-- Workers (id=BIGSERIAL auto, columns: code, password_hash, role, active)
-- password_hash = BCrypt('1234', 10)
INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, active, email, created_at, updated_at)
SELECT c.id, b.id, 'BORSI', 'Borsi Tamas',
    '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie',
    'CASHIER', true, 'borsi.tamas.ebc@gmail.com', NOW(), NOW()
FROM branch b JOIN company c ON b.company_id = c.id WHERE b.code = 'TISZA'
ON CONFLICT (company_id, code) DO NOTHING;

INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, active, email, created_at, updated_at)
SELECT c.id, b.id, 'BALI', 'Bali Henrietta',
    '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie',
    'CASHIER', true, 'bali.henriett.ebc@gmail.com', NOW(), NOW()
FROM branch b JOIN company c ON b.company_id = c.id WHERE b.code = 'TISZA'
ON CONFLICT (company_id, code) DO NOTHING;

INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, active, email, created_at, updated_at)
SELECT c.id, b.id, 'KASZA', 'Kasza Helga',
    '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie',
    'CASHIER', true, 'kasza.helga.ebc@gmail.com', NOW(), NOW()
FROM branch b JOIN company c ON b.company_id = c.id WHERE b.code = 'TISZA'
ON CONFLICT (company_id, code) DO NOTHING;
