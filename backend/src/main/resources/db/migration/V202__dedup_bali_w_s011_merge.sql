-- V202: BALI / W-S011 worker duplikacio megszuntetese.
--
-- A V146 dedup Borsi (W-S012), Kasza (W-S085), Kosa (W-S101) W-kodokat
-- deaktivalta, de BALI / W-S011 parost kihagyta (nev elteresek miatt).
-- Eredmeny: ket aktiv worker ugyanarrol a szemelyrrol:
--   BALI   = legacy V111 seed, 14 canonical role (V195 whitelist)
--   W-S011 = valos xlsx kod (V145), csak ertektar role -> setup hiba
--
-- Fix: W-S011 az elsodleges, BALI deaktivalva.

DO $$
DECLARE
    ebc_company_id UUID;
    bali_worker_id BIGINT;
    ws011_worker_id BIGINT;
BEGIN
    SELECT id INTO ebc_company_id FROM company WHERE code = 'EBC' LIMIT 1;
    IF ebc_company_id IS NULL THEN
        RAISE NOTICE 'V202: EBC ceg nem talalhato — migrate kihagyva.';
        RETURN;
    END IF;

    SELECT id INTO bali_worker_id FROM worker
    WHERE code = 'BALI' AND company_id = ebc_company_id LIMIT 1;

    SELECT id INTO ws011_worker_id FROM worker
    WHERE code = 'W-S011' AND company_id = ebc_company_id LIMIT 1;

    IF bali_worker_id IS NULL OR ws011_worker_id IS NULL THEN
        RAISE NOTICE 'V202: BALI vagy W-S011 worker nem talalhato — migrate kihagyva.';
        RETURN;
    END IF;

    -- 1. BALI osszes role-jat atmasoljuk W-S011-re (ON CONFLICT: meglevot nem irjuk felul)
    INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
    SELECT ws011_worker_id, role_def_id, is_primary
    FROM worker_role_assignment
    WHERE worker_id = bali_worker_id
    ON CONFLICT (worker_id, role_def_id) DO NOTHING;

    -- 2. W-S011 adatait frissitjuk a BALI-rol (email, google login, legacy role enum)
    UPDATE worker SET
        email = COALESCE((SELECT email FROM worker WHERE id = bali_worker_id), email),
        google_login_enabled = COALESCE((SELECT google_login_enabled FROM worker WHERE id = bali_worker_id), google_login_enabled),
        role = COALESCE((SELECT role FROM worker WHERE id = bali_worker_id), role),
        region = COALESCE((SELECT region FROM worker WHERE id = bali_worker_id), region)
    WHERE id = ws011_worker_id;

    -- 3. BALI deaktivalasa (soft delete — git history-ban megmarad a migration)
    UPDATE worker SET is_active = false WHERE id = bali_worker_id;

    -- 4. BALI role assignment-jeit toroljuk (mar atmasolva W-S011-re)
    DELETE FROM worker_role_assignment WHERE worker_id = bali_worker_id;

    RAISE NOTICE 'V202: BALI (id=%) deaktivalva, role-ok atmasolva W-S011-re (id=%).', bali_worker_id, ws011_worker_id;
END
$$;
