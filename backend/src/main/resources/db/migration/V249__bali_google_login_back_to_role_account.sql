-- V249: Bali Google-belépés visszahelyezése a SZEREPKÖR-fiókra (BALI) + a pénztáros-duplikátum
--       (W-S011) deaktiválása. Kósa Zoltán explicit jóváhagyásával (TESZT-adat).
--
-- ELŐZMÉNY: a V203/V204 korábban úgy döntött, hogy a MEGMARADÓ rekord a W-S011 (pénztáros-kód),
-- és a Bali Google-kötését BALI → W-S011 irányba vitte át. A mostani főértéktári elv ezt MEGFORDÍTJA:
-- Bali (főértéktárhelyettes/értéktáros) a SZEREPKÖR-fiókkal (BALI) lépjen be Google-fiókkal,
-- a pénztáros-azonosító (W-S011) pedig kivezetendő.
--
-- LOGIN-BIZTONSÁG: a GoogleLoginService a worker is_active-ját ÉS a google_login_enabled+email
-- whitelistet nézi. A kötést ATOMIKUSAN, a unique-indexeket tiszteletben tartva mozgatjuk:
--   uq_worker_google_subject (WHERE subject IS NOT NULL)         → előbb W-S011.google_subject = NULL
--   uq_worker_company_google_email_lower (WHERE login_enabled)   → előbb W-S011.google_login_enabled = false
-- Csak EZUTÁN állítjuk be a BALI-t → így Bali a művelet után BALI-val tud Google-belépni.
--
-- GUARDED: csak akkor fut, ha W-S011 a login-hordozó (aktív + google_login_enabled + van subject)
-- ÉS a megtartandó BALI aktív ÉS BALI-nak MÉG NINCS saját google_subject (nem írunk felül létezőt).
-- Idempotens: ismételt futáskor (W-S011 már nem login-hordozó) nincs teendő.

DO $$
DECLARE
    v_company UUID;
    v_bali BIGINT;
    v_ws011 BIGINT;
    v_sub TEXT;
    v_email TEXT;
    v_linked TIMESTAMP;
    v_lastlogin TIMESTAMP;
    v_bali_has_sub BOOLEAN;
BEGIN
    SELECT id INTO v_company FROM company WHERE code = 'EBC' LIMIT 1;
    IF v_company IS NULL THEN
        RAISE NOTICE 'V249: EBC cég nem található — kihagyva.';
        RETURN;
    END IF;

    SELECT id INTO v_bali  FROM worker WHERE code = 'BALI'   AND company_id = v_company LIMIT 1;
    SELECT id INTO v_ws011 FROM worker WHERE code = 'W-S011' AND company_id = v_company LIMIT 1;
    IF v_bali IS NULL OR v_ws011 IS NULL THEN
        RAISE NOTICE 'V249: BALI vagy W-S011 nem található — kihagyva.';
        RETURN;
    END IF;

    -- W-S011 a login-hordozó? (aktív + engedélyezett + van Google subject)
    SELECT google_subject, email, google_linked_at, google_last_login_at
      INTO v_sub, v_email, v_linked, v_lastlogin
      FROM worker
     WHERE id = v_ws011 AND is_active = true AND google_login_enabled = true AND google_subject IS NOT NULL;
    IF v_sub IS NULL THEN
        RAISE NOTICE 'V249: W-S011 nem login-hordozó (vagy már átállítva) — nincs teendő (idempotens).';
        RETURN;
    END IF;

    SELECT (google_subject IS NOT NULL) INTO v_bali_has_sub FROM worker WHERE id = v_bali AND is_active = true;
    IF v_bali_has_sub IS NULL THEN
        RAISE NOTICE 'V249: BALI nem aktív — kihagyva (nem hagyjuk login nélkül a duplikátum-deaktiválást).';
        RETURN;
    END IF;
    IF v_bali_has_sub THEN
        RAISE NOTICE 'V249: BALI-nak MÁR van saját google_subject — NEM írjuk felül; W-S011 ÉRINTETLEN (kézi ellenőrzés).';
        RETURN;
    END IF;

    -- 1) W-S011 kötés felszabadítása (unique-indexek), login letiltása
    UPDATE worker
       SET google_subject = NULL, google_login_enabled = false, google_linked_at = NULL, google_last_login_at = NULL,
           updated_at = NOW()
     WHERE id = v_ws011;

    -- 2) BALI-ra helyezés (most már nincs ütközés)
    UPDATE worker
       SET google_subject = v_sub, email = v_email, google_login_enabled = true,
           google_linked_at = COALESCE(v_linked, NOW()), google_last_login_at = v_lastlogin,
           updated_at = NOW()
     WHERE id = v_bali;

    -- 3) W-S011 (pénztáros-duplikátum) deaktiválása
    UPDATE worker SET is_active = false, updated_at = NOW() WHERE id = v_ws011;

    RAISE NOTICE 'V249: Bali Google-belépés áthelyezve W-S011 → BALI (subject=%); W-S011 deaktiválva. Bali mostantól BALI-val lép be.', v_sub;
END
$$;
