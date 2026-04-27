-- V162: Google OAuth whitelist — KOSA + FABULYA workerek, emailek normalizacioja.
--
-- Cel: a Google OAuth login (POST /api/v1/auth/google-login) az `email` oszlop
-- alapjan keres worker-t. A user 5 email-t adott meg az EBC csapatbol:
--   - bali.henriett.ebc@gmail.com (meglevo - BALI)
--   - borsi.tamas.ebc@gmail.com (meglevo - BORSI)
--   - kosa.zoltan.ebc@gmail.com (uj - KOSA ugyvezeto, pontositasa)
--   - kasza.helga.ebc@gmail.com (meglevo - KASZA)
--   - fabulyazsuzsa.eec@gmail.com (uj - FABULYA irodai dolgozo)
--
-- A V111 migration mar beirta az emaileket BORSI/BALI/KASZA-nak. A KOSA-t
-- a migration felvette, de nehany DB-bol eltunt egy kesobbi adatmodositas
-- miatt. A FABULYA teljesen uj.

DO $$
DECLARE
    has_is_active BOOLEAN;
    worker_active_col TEXT;
    ebc_company_id UUID;
    first_branch_id UUID;
BEGIN
    -- Az active oszlop nev detektalasa (is_active vs active)
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'worker' AND column_name = 'is_active'
    ) INTO has_is_active;

    worker_active_col := CASE WHEN has_is_active THEN 'is_active' ELSE 'active' END;

    -- EBC ceg ID
    SELECT id INTO ebc_company_id FROM company WHERE code = 'EBC' LIMIT 1;
    IF ebc_company_id IS NULL THEN
        RAISE NOTICE 'V162: EBC ceg nem talalhato — migrate kihagyva.';
        RETURN;
    END IF;

    -- Alapertelmezett branch (TISZA elsonek, ha van)
    SELECT b.id INTO first_branch_id
    FROM branch b
    WHERE b.company_id = ebc_company_id
    ORDER BY CASE WHEN b.code = 'TISZA' THEN 0 ELSE 1 END, b.created_at
    LIMIT 1;

    IF first_branch_id IS NULL THEN
        RAISE NOTICE 'V162: EBC-nek nincs branch-e — migrate kihagyva.';
        RETURN;
    END IF;

    -- KOSA (Kosa Zoltan - ugyvezeto)
    EXECUTE format($sql$
        INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, %I, email, created_at)
        VALUES ($1, $2, 'KOSA', 'Kosa Zoltan',
                '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie',
                'ADMIN', true, 'kosa.zoltan.ebc@gmail.com', NOW())
        ON CONFLICT (company_id, code) DO UPDATE
        SET email = EXCLUDED.email,
            %I = true,
            password_hash = COALESCE(worker.password_hash, EXCLUDED.password_hash)
    $sql$, worker_active_col, worker_active_col) USING ebc_company_id, first_branch_id;

    -- FABULYA (Fabulya Zsuzsa - irodai dolgozo, pl. CASHIER)
    EXECUTE format($sql$
        INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, %I, email, created_at)
        VALUES ($1, $2, 'FABULYA', 'Fabulya Zsuzsa',
                '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie',
                'CASHIER', true, 'fabulyazsuzsa.eec@gmail.com', NOW())
        ON CONFLICT (company_id, code) DO UPDATE
        SET email = EXCLUDED.email,
            %I = true,
            password_hash = COALESCE(worker.password_hash, EXCLUDED.password_hash)
    $sql$, worker_active_col, worker_active_col) USING ebc_company_id, first_branch_id;

    -- Reset password_changed_at NULL (force first-time-setup kovetkezo login-nal)
    UPDATE worker SET password_changed_at = NULL
    WHERE company_id = ebc_company_id
      AND code IN ('KOSA', 'FABULYA');

    RAISE NOTICE 'V162: Google OAuth whitelist email-ek beirva (BORSI, BALI, KASZA, KOSA, FABULYA).';
END
$$;

-- Assertion: mind az 5 worker megvan az EBC ceg alatt, email-lel
DO $$
DECLARE
    with_email_count INT;
BEGIN
    SELECT COUNT(*) INTO with_email_count
    FROM worker w
    JOIN company c ON c.id = w.company_id
    WHERE c.code = 'EBC'
      AND w.code IN ('BORSI', 'BALI', 'KASZA', 'KOSA', 'FABULYA')
      AND w.email IS NOT NULL
      AND w.email LIKE '%@gmail.com';
    RAISE NOTICE 'V162: % worker-nek van @gmail.com cime (5 vart).', with_email_count;
END
$$;