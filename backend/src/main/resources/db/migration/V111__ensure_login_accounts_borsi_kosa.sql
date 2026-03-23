-- V111: Ensure fallback login accounts (BORSI/BALI/KASZA/KOSA) for EBC
-- Purpose: stabilize troubleshooting logins where master data partially exists.
-- Password for ensured accounts: 1234 (BCrypt hash below).

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

    -- Ensure code BORSI
    EXECUTE format($sql$
        INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, %I, email, created_at)
        SELECT
            c.id,
            (
                SELECT b.id
                FROM branch b
                WHERE b.company_id = c.id
                ORDER BY CASE WHEN b.code = 'TISZA' THEN 0 ELSE 1 END, b.created_at
                LIMIT 1
            ),
            'BORSI', 'Borsi Tamas',
            '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie',
            'CASHIER', true, 'borsi.tamas.ebc@gmail.com', NOW()
        FROM company c
        WHERE c.code = 'EBC'
          AND EXISTS (SELECT 1 FROM branch b WHERE b.company_id = c.id)
        ON CONFLICT (company_id, code) DO UPDATE
        SET
            password_hash = EXCLUDED.password_hash,
            role = EXCLUDED.role,
            %I = TRUE,
            email = COALESCE(worker.email, EXCLUDED.email)
    $sql$, worker_active_col, worker_active_col);

    -- Ensure code BALI
    EXECUTE format($sql$
        INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, %I, email, created_at)
        SELECT
            c.id,
            (
                SELECT b.id
                FROM branch b
                WHERE b.company_id = c.id
                ORDER BY CASE WHEN b.code = 'TISZA' THEN 0 ELSE 1 END, b.created_at
                LIMIT 1
            ),
            'BALI', 'Bali Henrietta',
            '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie',
            'CASHIER', true, 'bali.henriett.ebc@gmail.com', NOW()
        FROM company c
        WHERE c.code = 'EBC'
          AND EXISTS (SELECT 1 FROM branch b WHERE b.company_id = c.id)
        ON CONFLICT (company_id, code) DO UPDATE
        SET
            password_hash = EXCLUDED.password_hash,
            role = EXCLUDED.role,
            %I = TRUE,
            email = COALESCE(worker.email, EXCLUDED.email)
    $sql$, worker_active_col, worker_active_col);

    -- Ensure code KASZA
    EXECUTE format($sql$
        INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, %I, email, created_at)
        SELECT
            c.id,
            (
                SELECT b.id
                FROM branch b
                WHERE b.company_id = c.id
                ORDER BY CASE WHEN b.code = 'TISZA' THEN 0 ELSE 1 END, b.created_at
                LIMIT 1
            ),
            'KASZA', 'Kasza Helga',
            '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie',
            'CASHIER', true, 'kasza.helga.ebc@gmail.com', NOW()
        FROM company c
        WHERE c.code = 'EBC'
          AND EXISTS (SELECT 1 FROM branch b WHERE b.company_id = c.id)
        ON CONFLICT (company_id, code) DO UPDATE
        SET
            password_hash = EXCLUDED.password_hash,
            role = EXCLUDED.role,
            %I = TRUE,
            email = COALESCE(worker.email, EXCLUDED.email)
    $sql$, worker_active_col, worker_active_col);

    -- Ensure code KOSA
    EXECUTE format($sql$
        INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, %I, email, created_at)
        SELECT
            c.id,
            (
                SELECT b.id
                FROM branch b
                WHERE b.company_id = c.id
                ORDER BY CASE WHEN b.code = 'TISZA' THEN 0 ELSE 1 END, b.created_at
                LIMIT 1
            ),
            'KOSA', 'Kosa Zoltan',
            '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie',
            'CASHIER', true, 'kosa.zoltan.ebc@gmail.com', NOW()
        FROM company c
        WHERE c.code = 'EBC'
          AND EXISTS (SELECT 1 FROM branch b WHERE b.company_id = c.id)
        ON CONFLICT (company_id, code) DO UPDATE
        SET
            password_hash = EXCLUDED.password_hash,
            role = EXCLUDED.role,
            %I = TRUE,
            email = COALESCE(worker.email, EXCLUDED.email)
    $sql$, worker_active_col, worker_active_col);
END
$$;
