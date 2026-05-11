-- V203: BALI / W-S011 worker duplikacio megszuntetese (v2, V202 rollback fix).
--
-- V202 unique constraint violation-nel elbukott production-on (uk_worker_email).
-- Root cause: BALI email-jet W-S011-re masoltuk, de BALI meg aktiv volt
-- ugyanazzal az email-lel -> constraint violation.
--
-- Fix: BALI email-jet eloszor NULL-azzuk (deaktivalas), AZUTAN masoljuk W-S011-re.
-- PostgreSQL DDL-tranzakcios: V202 teljes rollback -> nincs flyway_schema_history
-- rekord -> V203 friss migraciokent fut.

DO $$
DECLARE
    ebc_company_id UUID;
    bali_worker_id BIGINT;
    ws011_worker_id BIGINT;
    bali_email TEXT;
    bali_google_login BOOLEAN;
    bali_role TEXT;
    bali_region TEXT;
BEGIN
    SELECT id INTO ebc_company_id FROM company WHERE code = 'EBC' LIMIT 1;
    IF ebc_company_id IS NULL THEN
        RAISE NOTICE 'V203: EBC ceg nem talalhato — migrate kihagyva.';
        RETURN;
    END IF;

    SELECT id INTO bali_worker_id FROM worker
    WHERE code = 'BALI' AND company_id = ebc_company_id LIMIT 1;

    SELECT id INTO ws011_worker_id FROM worker
    WHERE code = 'W-S011' AND company_id = ebc_company_id LIMIT 1;

    IF bali_worker_id IS NULL OR ws011_worker_id IS NULL THEN
        RAISE NOTICE 'V203: BALI vagy W-S011 worker nem talalhato — migrate kihagyva.';
        RETURN;
    END IF;

    -- 0. BALI adatait elmentjuk valtozokba (mielott nullazzuk az email-t)
    SELECT email, google_login_enabled, role, region
    INTO bali_email, bali_google_login, bali_role, bali_region
    FROM worker WHERE id = bali_worker_id;

    -- 1. BALI osszes role-jat atmasoljuk W-S011-re (ON CONFLICT: meglevot nem irjuk felul)
    INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
    SELECT ws011_worker_id, role_def_id, is_primary
    FROM worker_role_assignment
    WHERE worker_id = bali_worker_id
    ON CONFLICT (worker_id, role_def_id) DO NOTHING;

    -- 2. BALI deaktivalasa + email nullazas ELOSZOR (uk_worker_email constraint!)
    UPDATE worker SET is_active = false, email = NULL WHERE id = bali_worker_id;

    -- 3. W-S011 adatait frissitjuk a mentett BALI adatokkal
    UPDATE worker SET
        email = COALESCE(bali_email, email),
        google_login_enabled = COALESCE(bali_google_login, google_login_enabled),
        role = COALESCE(bali_role, role),
        region = COALESCE(bali_region, region)
    WHERE id = ws011_worker_id;

    -- 4. BALI role assignment-jeit toroljuk (mar atmasolva W-S011-re)
    DELETE FROM worker_role_assignment WHERE worker_id = bali_worker_id;

    RAISE NOTICE 'V203: BALI (id=%) deaktivalva, role-ok atmasolva W-S011-re (id=%).', bali_worker_id, ws011_worker_id;
END
$$;
