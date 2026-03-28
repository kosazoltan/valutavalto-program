-- Seed data for fresh install (replaces Flyway V69 + V70 seed)
-- Run as postgres user against valuta database

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
-- Note: company.code UNIQUE constraint needed (JPA @Column unique=true)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uk_company_code') THEN
    ALTER TABLE company ADD CONSTRAINT uk_company_code UNIQUE (code);
  END IF;
END $$;

INSERT INTO company (id, name, code, is_active, created_at)
VALUES (gen_random_uuid(), 'Exclusive Best Change Zrt.', 'EBC', true, NOW())
ON CONFLICT (code) DO NOTHING;

-- Branch: Tisza Sarok (Szeged)
INSERT INTO branch (id, company_id, name, code, bank_code, city, address, zip_code,
    opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at)
SELECT
    gen_random_uuid(), c.id,
    'Tisza Sarok', 'TISZA', 'TISZA', 'Szeged', 'Tisza Sarok, Szeged', '6720',
    CURRENT_DATE, true,
    (SELECT id FROM dictionary WHERE category = 'BRANCH_TYPE'   AND code = 'PENZTAR'),
    (SELECT id FROM dictionary WHERE category = 'COUNTRY'       AND code = 'HU'),
    (SELECT id FROM dictionary WHERE category = 'BRANCH_STATUS' AND code = 'ACTIVE'),
    NOW()
FROM company c WHERE c.code = 'EBC'
ON CONFLICT (code) DO NOTHING;

-- Workers: password_hash = BCrypt('1234'), column is_active (matches @Column(name="is_active"))
INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, is_active, email, created_at)
SELECT c.id, b.id, 'BORSI', 'Borsi Tamas',
    '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie',
    'CASHIER', true, 'borsi.tamas.ebc@gmail.com', NOW()
FROM branch b JOIN company c ON b.company_id = c.id WHERE b.code = 'TISZA'
ON CONFLICT (company_id, code) DO NOTHING;

INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, is_active, email, created_at)
SELECT c.id, b.id, 'BALI', 'Bali Henrietta',
    '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie',
    'CASHIER', true, 'bali.henriett.ebc@gmail.com', NOW()
FROM branch b JOIN company c ON b.company_id = c.id WHERE b.code = 'TISZA'
ON CONFLICT (company_id, code) DO NOTHING;

INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, is_active, email, created_at)
SELECT c.id, b.id, 'KASZA', 'Kasza Helga',
    '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie',
    'CASHIER', true, 'kasza.helga.ebc@gmail.com', NOW()
FROM branch b JOIN company c ON b.company_id = c.id WHERE b.code = 'TISZA'
ON CONFLICT (company_id, code) DO NOTHING;

-- Seed currencies: id=BIGSERIAL, no name_hu column, decimal_places required
INSERT INTO currency (code, name, is_active, decimal_places, created_at)
VALUES
  ('EUR', 'Euro', true, 2, NOW()),
  ('USD', 'US Dollar', true, 2, NOW()),
  ('GBP', 'British Pound', true, 2, NOW()),
  ('CHF', 'Swiss Franc', true, 2, NOW()),
  ('CZK', 'Czech Koruna', true, 2, NOW()),
  ('PLN', 'Polish Zloty', true, 2, NOW()),
  ('RON', 'Romanian Leu', true, 2, NOW()),
  ('RSD', 'Serbian Dinar', true, 0, NOW()),
  ('HRK', 'Croatian Kuna', true, 2, NOW()),
  ('NOK', 'Norwegian Krone', true, 2, NOW()),
  ('SEK', 'Swedish Krona', true, 2, NOW()),
  ('DKK', 'Danish Krone', true, 2, NOW()),
  ('CAD', 'Canadian Dollar', true, 2, NOW()),
  ('AUD', 'Australian Dollar', true, 2, NOW()),
  ('JPY', 'Japanese Yen', true, 0, NOW()),
  ('TRY', 'Turkish Lira', true, 2, NOW()),
  ('HUF', 'Hungarian Forint', true, 0, NOW())
ON CONFLICT (code) DO NOTHING;
