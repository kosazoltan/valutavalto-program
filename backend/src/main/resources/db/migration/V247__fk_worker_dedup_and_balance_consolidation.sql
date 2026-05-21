-- V247: FK törzsadat-revízió — egyenleg-konszolidáció (Kósa Zoltán explicit kérése, TESZT-adat).
--
--   A) Dolgozói dedup (BORSI/BALI) — SZÁNDÉKOSAN KIVÉVE ebből a migrációból.
--      Borsi (főértéktáros) és Bali (főértéktárhelyettes/értéktáros) BELÉPNEK a programba;
--      a GoogleLoginService a worker is_active-ját ellenőrzi (inaktív → belépés megtagadva).
--      Ezért a dedup csak login-tudatosan végezhető (login-hordozó rekord marad), külön migrációban.
--
--   B) Egyenleg-konszolidáció a (V246-ban) deaktivált pénztárakról a területi cél-egységbe:
--        - KORUT → BR020 (Szeged Értéktár)        [FK-002 területi modell: pénztár → területe értéktára]
--        - TISZA → BR035 (Szeged Tisza Sarok)     [FK-001 duplikátum-pár]
--
-- FONTOS — KONTEXTUS ÉS BIZTONSÁG:
--   * A V244 elve („egyenleg = könyvelési művelet, NEM nyers SQL-merge") az ÉLES adatra szól.
--     Ez TESZT-adatbázis, ahol a cash_balance eleve SEEDELT (V83, transfer-rekord nélkül), így a
--     seed-konzisztens, per-valuta upsert-konszolidáció itt megfelelő és auditált.
--     ÉLESBEN a valódi átadás-átvétel workflow (Transfer-rekorddal) a helyes út.
--   * Idempotens: a forrás-egyenleg nullázása után újrafutáskor nincs mit áthelyezni.
--   * Guarded: hiányzó forrás/cél esetén NOTICE + kihagyás.

DO $$
DECLARE
    v_korut UUID; v_tisza UUID; v_br020 UUID; v_br035 UUID;
    v_cnt INT;
BEGIN
    -- ===== A) Dolgozói dedup — KIVÉVE (login-biztonsági ok) =====
    -- FONTOS: Borsi (főértéktáros) és Bali (főértéktárhelyettes/értéktáros) BELÉPNEK a programba.
    -- A GoogleLoginService a worker is_active-ját ELLENŐRZI (inaktív → belépés megtagadva), és a
    -- whitelist e-mail + google_login_enabled EGYIK rekordhoz (legacy BORSI/BALI VAGY kanonikus
    -- W-S012/W-S011) van kötve. Ha a login a legacy kódon van, annak deaktiválása KIZÁRNÁ őket.
    -- Ezért a worker-dedup CSAK login-tudatosan végezhető (a login-hordozó rekord marad aktív,
    -- a login NÉLKÜLI duplikátum deaktiválandó) — ez külön, guarded migrációban történik, miután
    -- igazoltuk, melyik rekord viseli a Google-bejelentkezést. ITT NEM nyúlunk a worker-ekhez.

    -- ===== B) Egyenleg-konszolidáció =====
    SELECT id INTO v_korut FROM branch WHERE code = 'KORUT' LIMIT 1;
    SELECT id INTO v_tisza FROM branch WHERE code = 'TISZA' LIMIT 1;
    SELECT id INTO v_br020 FROM branch WHERE code = 'BR020' AND is_active = true LIMIT 1;  -- Szeged Értéktár
    SELECT id INTO v_br035 FROM branch WHERE code = 'BR035' AND is_active = true LIMIT 1;  -- Szeged Tisza Sarok

    -- KORUT → BR020 (Szeged Értéktár)
    IF v_korut IS NOT NULL AND v_br020 IS NOT NULL THEN
        INSERT INTO cash_balance (company_id, branch_id, currency_id, current_balance, opening_balance, created_at, version)
        SELECT s.company_id, v_br020, s.currency_id, s.current_balance, 0, NOW(), 0
          FROM cash_balance s
         WHERE s.branch_id = v_korut AND s.current_balance <> 0
        ON CONFLICT (branch_id, currency_id) DO UPDATE
            SET current_balance = cash_balance.current_balance + EXCLUDED.current_balance,
                updated_at = NOW();
        GET DIAGNOSTICS v_cnt = ROW_COUNT;
        UPDATE cash_balance SET current_balance = 0, updated_at = NOW()
         WHERE branch_id = v_korut AND current_balance <> 0;
        RAISE NOTICE 'FK-003 konszolidáció: KORUT → Szeged Értéktár (BR020), % valuta-sor áthelyezve.', v_cnt;
    ELSE
        RAISE NOTICE 'FK-003 konszolidáció: KORUT vagy BR020 nem található — kihagyva.';
    END IF;

    -- TISZA → BR035 (Szeged Tisza Sarok)
    IF v_tisza IS NOT NULL AND v_br035 IS NOT NULL THEN
        INSERT INTO cash_balance (company_id, branch_id, currency_id, current_balance, opening_balance, created_at, version)
        SELECT s.company_id, v_br035, s.currency_id, s.current_balance, 0, NOW(), 0
          FROM cash_balance s
         WHERE s.branch_id = v_tisza AND s.current_balance <> 0
        ON CONFLICT (branch_id, currency_id) DO UPDATE
            SET current_balance = cash_balance.current_balance + EXCLUDED.current_balance,
                updated_at = NOW();
        GET DIAGNOSTICS v_cnt = ROW_COUNT;
        UPDATE cash_balance SET current_balance = 0, updated_at = NOW()
         WHERE branch_id = v_tisza AND current_balance <> 0;
        RAISE NOTICE 'FK-003 konszolidáció: TISZA → Szeged Tisza Sarok (BR035), % valuta-sor áthelyezve.', v_cnt;
    ELSE
        RAISE NOTICE 'FK-003 konszolidáció: TISZA vagy BR035 nem található — kihagyva.';
    END IF;
END $$;
