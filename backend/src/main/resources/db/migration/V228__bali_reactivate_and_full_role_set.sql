-- V228: BALI reaktivalas + teljes role-assignment a BALI / W-S011 dolgozokra
--
-- ============================================================================
-- ELOZMENY
-- ============================================================================
-- 2026-05-13 V203 dedup BALI-t deaktivalta es a roleait/email-jet W-S011-be
-- transzferalta. Emiatt a BALI BCrypt jelszovel mar NEM lehetett belepni a
-- penztari kliensbe (a hash a BALI workeren maradt, NEM W-S011-en).
--
-- 2026-05-13 V222 W-S011 minden role-jat eltavolitotta, kiveve penztar +
-- foertektar. Ez egy "over-permissive 14 role" incident reakcioja volt.
--
-- 2026-05-15 USER-DIREKTIVA (Kosa Zoltan):
-- - BALI reaktivalas (BCrypt belepes a penztari kliensbe MEG MUKODJON).
-- - W-S011 -> teljes role-set: penztar, foertektar, ertektar, belso_ellenor,
--   teruleti_vezeto, ugyvezeto, biztonsagi_vezeto.
-- - "Nincs duplikalt dolgozo, nincs duplikalt hozzaferes" — BALI csak BCrypt-en
--   (email maradjon NULL), W-S011 marad a Google OAuth hozzaferest.
-- - Google OAuth: a foertektar/ertektar/belso_ellenor/teruleti_vezeto/ugyvezeto/
--   biztonsagi_vezeto role-okhoz, email + Google authentikacioval.
-- ============================================================================

DO $$
DECLARE
    ebc_company_id UUID;
    bali_worker_id BIGINT;
    ws011_worker_id BIGINT;
    role_added_count INT := 0;
    bali_email TEXT;
BEGIN
    SELECT id INTO ebc_company_id FROM company WHERE code = 'EBC' LIMIT 1;
    IF ebc_company_id IS NULL THEN
        RAISE NOTICE 'V228: EBC ceg nem talalhato — migrate kihagyva.';
        RETURN;
    END IF;

    SELECT id INTO bali_worker_id FROM worker
    WHERE code = 'BALI' AND company_id = ebc_company_id LIMIT 1;

    SELECT id INTO ws011_worker_id FROM worker
    WHERE code = 'W-S011' AND company_id = ebc_company_id LIMIT 1;

    -- ============================================================================
    -- 1. BALI REAKTIVALAS — BCrypt belepes a penztari kliensbe MUKODJON megint
    -- ============================================================================
    -- A BALI worker email-je NULL marad (W-S011-en van az aktiv email),
    -- google_login_enabled FALSE marad (BALI nem hasznalhat Google OAuth-ot).
    -- CSAK a BCrypt jelszo + role-assignment-ek elerheto.
    IF bali_worker_id IS NOT NULL THEN
        UPDATE worker
        SET is_active = TRUE
        WHERE id = bali_worker_id;
        RAISE NOTICE 'V228: BALI (id=%) reaktivalva.', bali_worker_id;
    ELSE
        RAISE NOTICE 'V228: BALI worker nem letezik a DB-ben — kihagyva.';
    END IF;

    -- ============================================================================
    -- 2. BALI teljes role-set (BCrypt-tel ezeket latja a penztari + kozponti modul)
    -- ============================================================================
    -- penztar = penztarosi munka (BUY/SELL/CONVERSION)
    -- foertektar = arfolyamkeszites + banki riport
    -- ertektar = ertektar atadas/atvetel + napi/dekad/havi zaras
    -- belso_ellenor = audit, rovancsolas, compliance
    -- teruleti_vezeto = teruleti vezeto, penztarak felugyelete
    -- ugyvezeto = teljes szerver-hozzaferes
    -- biztonsagi_vezeto = kamerak, ertekszallito ellenorzes
    IF bali_worker_id IS NOT NULL THEN
        INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
        SELECT bali_worker_id, r.id, (r.code = 'penztar')
        FROM worker_role_def r
        WHERE r.code IN ('penztar', 'foertektar', 'ertektar', 'belso_ellenor',
                         'teruleti_vezeto', 'ugyvezeto', 'biztonsagi_vezeto')
        ON CONFLICT (worker_id, role_def_id) DO NOTHING;
        GET DIAGNOSTICS role_added_count = ROW_COUNT;
        RAISE NOTICE 'V228: BALI-ra % role hozzarendelve.', role_added_count;
    END IF;

    -- ============================================================================
    -- 3. W-S011 teljes role-set — V222 V228 user-direktiva alapjan visszaaalitva
    -- ============================================================================
    -- Az ugyanazok a role-ok mint BALI-nak, de W-S011 az aki a Google OAuth email-t
    -- birja (V203 transzferalta). A foertektar marad a primary.
    IF ws011_worker_id IS NOT NULL THEN
        INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
        SELECT ws011_worker_id, r.id, (r.code = 'foertektar')
        FROM worker_role_def r
        WHERE r.code IN ('penztar', 'foertektar', 'ertektar', 'belso_ellenor',
                         'teruleti_vezeto', 'ugyvezeto', 'biztonsagi_vezeto')
        ON CONFLICT (worker_id, role_def_id) DO NOTHING;
        GET DIAGNOSTICS role_added_count = ROW_COUNT;
        RAISE NOTICE 'V228: W-S011-re % role hozzarendelve.', role_added_count;

        -- Biztositsuk hogy W-S011 google_login_enabled=TRUE marad
        UPDATE worker
        SET google_login_enabled = TRUE
        WHERE id = ws011_worker_id;

        -- Ellenoorzes: van-e email?
        SELECT email INTO bali_email FROM worker WHERE id = ws011_worker_id;
        IF bali_email IS NULL THEN
            RAISE NOTICE 'V228 WARNING: W-S011 email NULL — Google OAuth NEM mukodik amig az admin nem allitja be.';
        ELSE
            RAISE NOTICE 'V228: W-S011 email=% Google OAuth elerheto.', bali_email;
        END IF;
    END IF;
END
$$;
