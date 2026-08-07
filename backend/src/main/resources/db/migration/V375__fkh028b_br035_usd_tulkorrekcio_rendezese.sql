-- V375: FKH-028/B — BR035 penztar USD-egyenlegenek korrekcioja (-2000 USD)
--
-- ============================================================================
-- GYOKEROK
-- ============================================================================
-- A V370 migracio (+1000 USD) TULKORRIGALT, mert egy MAR RENDEZETT allapotot
-- feltetelezett rendezetlennek. A prod-vizsgalat (2026-08-07) bizonyitotta:
--
--   AT-000009.cancelled_at = 2026-08-02 18:50:52
--   V370 installed_on      = 2026-08-04 14:12:24   <- 44 oraval KESOBB
--
-- A BR035 penztarnak OSSZESEN 4 db USD-tranzakcioja van valaha (count(*)=4,
-- szures nelkul), tehat a teljes USD-tortenet ismert:
--
--   AA035100002  TRANSFER_OUT  COMPLETED  1000  (AT-000009)      07-31 12:21:43.37
--   AA035100003  TRANSFER_OUT  REVERSED   1000  (AT-000010)      07-31 12:21:43.78
--   AA035100004  REVERSAL      COMPLETED  1000  (AA035100003-ra) 07-31 12:25:01
--   AV035100005  TRANSFER_IN   COMPLETED  1000  (AT-000009-SZ)   08-02 18:50:52
--
-- Idorend:
--   07-31 12:21  dupla bekuldes (AT-000009 + AT-000010)      BR035: -2000
--   07-31 12:25  app-sztorno az AT-000010 tranzakciojara     BR035: +1000  -> -1000  (helyes)
--   08-02 18:50  PENDING-sztorno az AT-000009-re             BR035: +1000  ->     0  (tulzas)
--   08-04 14:12  V370 migracio                               BR035: +1000  -> +1000  (tulkorrekcio)
--   08-05 17:15  BR020 ATVESZI az AT-000010-et               BR020: +1000
--
-- A negy tranzakcio netto hatasa BR035-re PONTOSAN NULLA, holott a valosagban
-- 1000 USD fizikailag elment BR020-ba (AV020100003 / COMPLETED / BR020 egyenleg=1000).
-- Ket visszairas tortent egy valodi atadasra, plusz a V370 harmadik.
--
--   nyito X-bol:  X -1000 -1000 +1000 +1000 +1000(V370) = X + 1000 = 5797  ->  X = 4797
--   helyes zaro:  X - 1000 = 3797      (egy valodi atadas ment el)
--   korrekcio:    5797 -> 3797  =  -2000.00 USD
--
-- KONTROLL (miert nem -1000): ha 4797 maradna, a BR035 konyvei szerint az 1000 USD
-- NEM hagyta el a kasszat, mikozben BR020 igazoltan megkapta -> ugyanaz a penz ketszer
-- szerepelne a ceg vagyonaban.
--
-- NFR-3 (mas legitim mozgas nem serulhet): a BR035 cash_balance.updated_at
-- (2026-08-05 07:15:16) PONTOSAN a daily_session napnyitas idobelyege, nem USD-mozgas.
-- A V370 ota legitim USD-forgalom NEM tortent.
--
-- ============================================================================
-- TBD-4 TANULSAG — ALLAPOT-ELLENORZES, NEM CSAK MARKER (uj konvencio)
-- ============================================================================
-- A V370 azert tudott tulkorrigalni, mert MARKER-alapu idempotenciat hasznalt
-- ("ha nincs jeloles, korrigalj"), de NEM ellenorizte, hogy a korrigalando allapot
-- fennall-e egyaltalan. A marker csak az ISMETELT FUTAS ellen ved, a HIBAS KIINDULO
-- ALLAPOT ellen nem.
--
-- Ez a migracio ezert FAIL-CLOSED allapot-ellenorzest vegez: kizarolag akkor ir,
-- ha a jelenlegi egyenleg PONTOSAN a vart 5797.00. Barmely eltero ertek eseten
-- NEM NYUL HOZZA, es RAISE NOTICE-szal jelez (kezi vizsgalat szukseges).
-- Igy ha a migracio kesobb, mar megvaltozott adatokon futna le, nem okoz uj kart.
--
-- SCOPE / BIZTONSAG:
--   - Fiok-feloldas kizarolag kodos lookuppal (BR035 + EBC + is_active), a V370/V368 mintajara.
--   - SZANDEKOSAN NINCS audit_log INSERT (V234 hash-lanc vedelme, V368/V370 precedens).
--   - A transfer/transaction sorokat NEM modositja: az AT-000010 reteg-ellentmondasa
--     (transfer COMPLETED + tranzakcio REVERSED, ezert az elment 1000 USD hianyzik a
--     forgalmi riportokbol) KULON FKH-ban rendezendo, user-dontes alapjan (2026-08-07).
--
-- ELLENORZO SELECT (elotte/utana):
--   SELECT b.code, c.code AS currency, cb.current_balance, cb.updated_at
--     FROM cash_balance cb
--     JOIN branch b   ON b.id  = cb.branch_id
--     JOIN company co ON co.id = b.company_id
--     JOIN currency c ON c.id  = cb.currency_id
--    WHERE co.code = 'EBC' AND b.code = 'BR035' AND b.is_active = TRUE AND c.code = 'USD';

DO $$
DECLARE
    v_company_id UUID;
    v_branch_id  UUID;
    v_usd_id     BIGINT;
    v_before     NUMERIC;
    v_expected   CONSTANT NUMERIC := 5797.00;   -- a V370 tulkorrekcio utani, meresi ertek
    v_target     CONSTANT NUMERIC := 3797.00;   -- a levezetett helyes egyenleg
    v_rows       INT;
BEGIN
    SELECT b.id, b.company_id
      INTO v_branch_id, v_company_id
      FROM branch b
      JOIN company co ON co.id = b.company_id
     WHERE b.code = 'BR035'
       AND co.code = 'EBC'
       AND b.is_active = TRUE
     LIMIT 1;

    IF v_branch_id IS NULL THEN
        RAISE NOTICE 'V375: aktiv BR035 branch (EBC ceg) nem talalhato — nincs teendo.';
        RETURN;
    END IF;

    SELECT id INTO v_usd_id FROM currency WHERE code = 'USD' LIMIT 1;
    IF v_usd_id IS NULL THEN
        RAISE NOTICE 'V375: USD currency torzsadat nem talalhato — nincs teendo.';
        RETURN;
    END IF;

    SELECT current_balance INTO v_before
      FROM cash_balance
     WHERE company_id = v_company_id AND branch_id = v_branch_id AND currency_id = v_usd_id;

    IF v_before IS NULL THEN
        RAISE NOTICE 'V375: BR035 USD cash_balance sor nem letezik — a korrekcio NEM futott le (kezi vizsgalat szukseges).';
        RETURN;
    END IF;

    -- TBD-4: ALLAPOT-ELLENORZES (fail-closed). A marker-alapu idempotencia onmagaban
    -- NEM eleg — a V370 pontosan azert tulkorrigalt, mert nem nezte meg a kiindulo allapotot.
    IF v_before = v_target THEN
        RAISE NOTICE 'V375: a korrekcio MAR alkalmazva (BR035 USD = %) — nincs teendo (idempotens).', v_target;
        RETURN;
    END IF;

    IF v_before <> v_expected THEN
        RAISE NOTICE 'V375: BR035 USD egyenlege (%) NEM a vart % — a korrekcio NEM fut le. '
                     'Idokozben valtozott az adat; kezi vizsgalat szukseges (FKH-028/B).',
                     v_before, v_expected;
        RETURN;
    END IF;

    UPDATE cash_balance
       SET current_balance = v_target,
           updated_at = NOW()
     WHERE company_id = v_company_id
       AND branch_id = v_branch_id
       AND currency_id = v_usd_id
       AND current_balance = v_expected;   -- optimista guard: parhuzamos iras ellen
    GET DIAGNOSTICS v_rows = ROW_COUNT;

    IF v_rows = 1 THEN
        RAISE NOTICE 'V375: BR035 USD % -> % (-2000.00, V370 tulkorrekcio rendezese).',
            v_before, v_target;
    ELSE
        RAISE NOTICE 'V375: a korrekcios UPDATE 0 sort erintett (parhuzamos valtozas?) — kezi vizsgalat szukseges.';
    END IF;
END $$;
