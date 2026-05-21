-- V248: Dolgozói duplikátum-dedup — LOGIN-TUDATOS, biztonságos (Kósa Zoltán + Kasza Helga).
--
-- SZEGED régióban két személy KÉT worker-rekorddal szerepel (legacy szerepkör-kód + pénztáros W-kód):
--   - Borsi Tamás:     megtartandó = BORSI  (főértéktáros, Google-login)   ; duplikátum = W-S012
--   - Bali Henrietta:  megtartandó = BALI   (főértéktárhelyettes/értéktáros, Google-login) ; duplikátum = W-S011
--
-- A felhasználói elv: Borsi/Bali a SZEREPKÖR-fiókkal (BORSI/BALI), Google-fiókkal lépnek be;
-- a pénztáros-azonosítókat (W-S012/W-S011) NE használják → ezek a duplikátumok kivezetendők.
--
-- LOGIN-BIZTONSÁG (KRITIKUS): a GoogleLoginService a worker is_active-ját ellenőrzi
-- (inaktív → belépés MEGTAGADVA). Ezért:
--   * A megtartandó BORSI/BALI MARAD aktív (login + szerepkör).
--   * A W-S012/W-S011 CSAK akkor deaktiválandó, ha (a) a megtartandó BORSI/BALI AKTÍV, ÉS
--     (b) a duplikátumon NINCS google_login_enabled (azaz nem ő a login-hordozó).
--     Ha a duplikátumon mégis VAN Google-login → NEM deaktiváljuk, NOTICE jelzi (előbb a
--     login-kötést kézzel a BORSI/BALI rekordra kell helyezni). Így login SOHA nem törhet be.
-- Idempotens, guarded.

DO $$
DECLARE
    v_cnt INT;
BEGIN
    -- ===== Borsi Tamás: BORSI (megtart) / W-S012 (duplikátum) =====
    IF EXISTS (SELECT 1 FROM worker WHERE code = 'BORSI' AND is_active = true) THEN
        UPDATE worker SET is_active = false, updated_at = NOW()
         WHERE code = 'W-S012' AND is_active = true
           AND COALESCE(google_login_enabled, false) = false;
        GET DIAGNOSTICS v_cnt = ROW_COUNT;
        IF v_cnt > 0 THEN
            RAISE NOTICE 'worker-dedup: W-S012 (Borsi pénztáros-duplikátum) DEAKTIVÁLVA; BORSI (login) marad aktív.';
        ELSIF EXISTS (SELECT 1 FROM worker WHERE code = 'W-S012' AND is_active = true AND google_login_enabled = true) THEN
            RAISE NOTICE 'worker-dedup FIGYELEM: W-S012-n VAN Google-login → NEM deaktiválva. Előbb a login-kötést a BORSI rekordra kell helyezni (kézi).';
        ELSE
            RAISE NOTICE 'worker-dedup: W-S012 már inaktív vagy nincs — nincs teendő (idempotens).';
        END IF;
    ELSE
        RAISE NOTICE 'worker-dedup: nincs AKTÍV BORSI (megtartandó) — W-S012 ÉRINTETLEN (nem árvítjuk a személyt).';
    END IF;

    -- ===== Bali Henrietta: BALI (megtart) / W-S011 (duplikátum) =====
    IF EXISTS (SELECT 1 FROM worker WHERE code = 'BALI' AND is_active = true) THEN
        UPDATE worker SET is_active = false, updated_at = NOW()
         WHERE code = 'W-S011' AND is_active = true
           AND COALESCE(google_login_enabled, false) = false;
        GET DIAGNOSTICS v_cnt = ROW_COUNT;
        IF v_cnt > 0 THEN
            RAISE NOTICE 'worker-dedup: W-S011 (Bali pénztáros-duplikátum) DEAKTIVÁLVA; BALI (login) marad aktív.';
        ELSIF EXISTS (SELECT 1 FROM worker WHERE code = 'W-S011' AND is_active = true AND google_login_enabled = true) THEN
            RAISE NOTICE 'worker-dedup FIGYELEM: W-S011-n VAN Google-login → NEM deaktiválva. Előbb a login-kötést a BALI rekordra kell helyezni (kézi).';
        ELSE
            RAISE NOTICE 'worker-dedup: W-S011 már inaktív vagy nincs — nincs teendő (idempotens).';
        END IF;
    ELSE
        RAISE NOTICE 'worker-dedup: nincs AKTÍV BALI (megtartandó) — W-S011 ÉRINTETLEN (nem árvítjuk a személyt).';
    END IF;
END $$;
