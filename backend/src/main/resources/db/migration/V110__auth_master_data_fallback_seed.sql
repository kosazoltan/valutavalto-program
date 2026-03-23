-- V110: Fallback auth master data seed (company/branch/workers)
-- Goal: ensure login-capable master data exists even on partially initialized DBs.

-- 1) Dictionary values required by branch seed
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'BRANCH_STATUS', 'ACTIVE', 'Active', 'Aktiv', 1, true, NOW())
ON CONFLICT (category, code) DO NOTHING;

INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'BRANCH_TYPE', 'PENZTAR', 'Cash Office', 'Penztar', 4, true, NOW())
ON CONFLICT (category, code) DO NOTHING;

INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'COUNTRY', 'HU', 'Hungary', 'Magyarorszag', 1, true, NOW())
ON CONFLICT (category, code) DO NOTHING;

-- 2) Company fallback
INSERT INTO company (id, name, code, is_active, created_at)
VALUES (gen_random_uuid(), 'Exclusive Best Change Zrt.', 'EBC', true, NOW())
ON CONFLICT (code) DO NOTHING;

-- 3) Branch fallback under EBC
INSERT INTO branch (id, company_id, name, code, bank_code, city, address, zip_code,
    opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at)
SELECT
    gen_random_uuid(), c.id,
    'Tisza Sarok', 'TISZA', 'TISZA', 'Szeged', 'Tisza Sarok, Szeged', '6720',
    CURRENT_DATE, true,
    (SELECT id FROM dictionary WHERE category = 'BRANCH_TYPE' AND code = 'PENZTAR' LIMIT 1),
    (SELECT id FROM dictionary WHERE category = 'COUNTRY' AND code = 'HU' LIMIT 1),
    (SELECT id FROM dictionary WHERE category = 'BRANCH_STATUS' AND code = 'ACTIVE' LIMIT 1),
    NOW()
FROM company c
WHERE c.code = 'EBC'
ON CONFLICT (code) DO NOTHING;

-- 4) Worker fallback
-- BCrypt hash for password "1234"
DO $$
DECLARE
    has_is_active BOOLEAN;
    has_active BOOLEAN;
    worker_active_col TEXT;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'worker'
          AND column_name = 'is_active'
    ) INTO has_is_active;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'worker'
          AND column_name = 'active'
    ) INTO has_active;

    worker_active_col := CASE
        WHEN has_is_active THEN 'is_active'
        WHEN has_active THEN 'active'
        ELSE NULL
    END;

    IF worker_active_col IS NULL THEN
        RAISE EXCEPTION 'worker table does not contain active/is_active column';
    END IF;

    EXECUTE format($sql$
        INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, %I, email, created_at)
        SELECT c.id, b.id, 'BORSI', 'Borsi Tamas',
            '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie',
            'CASHIER', true, 'borsi.tamas.ebc@gmail.com', NOW()
        FROM branch b
        JOIN company c ON b.company_id = c.id
        WHERE b.code = 'TISZA' AND c.code = 'EBC'
        ON CONFLICT (company_id, code) DO NOTHING
    $sql$, worker_active_col);

    EXECUTE format($sql$
        INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, %I, email, created_at)
        SELECT c.id, b.id, 'BALI', 'Bali Henrietta',
            '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie',
            'CASHIER', true, 'bali.henriett.ebc@gmail.com', NOW()
        FROM branch b
        JOIN company c ON b.company_id = c.id
        WHERE b.code = 'TISZA' AND c.code = 'EBC'
        ON CONFLICT (company_id, code) DO NOTHING
    $sql$, worker_active_col);

    EXECUTE format($sql$
        INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, %I, email, created_at)
        SELECT c.id, b.id, 'KASZA', 'Kasza Helga',
            '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie',
            'CASHIER', true, 'kasza.helga.ebc@gmail.com', NOW()
        FROM branch b
        JOIN company c ON b.company_id = c.id
        WHERE b.code = 'TISZA' AND c.code = 'EBC'
        ON CONFLICT (company_id, code) DO NOTHING
    $sql$, worker_active_col);
END
$$;
