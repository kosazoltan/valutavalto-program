-- V368: FK-070 — BR035 "Szeged Tisza Sarok" EUR/USD cash_balance egyszeri korrekcio egesz ertekre.
--
-- GYOKEROK / KONTEXTUS (FK-070 + FELTERKEPEZES_138):
--   A BR035 penztar EUR es USD cash_balance egyenlege tort (centes) erteket tartalmaz
--   (EUR 14334.45, USD 5797.57) — korabbi, nem eles tesztadat-maradvany, nem valos
--   tranzakciobol ered (a valosagban tort cimlet/erme rogzitese nem fordul elo).
--   A tort egyenleg az elo napi zaras (DAILY zaras-varazslo) veglegesiteset blokkolja.
--
-- ELO ELLENORZES (FK 9.1/4, 2026-07-30, read-only diag workflow run 30531322578, elo DB):
--   BR035 EUR current_balance = 14334.45 (updated_at 2026-07-28 10:01),
--   BR035 USD current_balance = 5797.57  (updated_at 2026-07-02 16:42) — a vart hibas ertekek.
--
-- KORREKCIO: EUR 14334.45 -> 14334.00; USD 5797.57 -> 5797.00.
--
-- BIZTONSAG / SCOPE:
--   - Fiok-feloldas KIZAROLAG kodos lookuppal: branch.code='BR035' + company.code='EBC'
--     + branch.is_active=TRUE. Nev szerinti kereses TILOS (tortenelmileg ket rekord letezett
--     ugyanarra a helyszinre, az egyik deaktivalva — l. V244 TISZA-duplikatum).
--   - Mindket UPDATE a current_balance = <ismert hibas ertek> orfeltetellel vedve (FR-3):
--     ha az egyenleg idokozben megvaltozott, a korrekcio NEM fut le, es ezt RAISE NOTICE
--     jelzi (0 erintett sor) — nem hibazik le csendben (FR-6).
--   - Idempotens (NFR-1): masodik futas 0 sort erint, mert a WHERE-feltetel mar nem teljesul.
--   - Mas fiok, mas valuta, a V035000001 AUD-tranzakcio es a zarasi munkamenet egyeb adatai
--     (lepes-allapotok stb.) ERINTETLENEK.
--   - SZANDEKOSAN NINCS audit_log INSERT (FR-4, FELTERKEPEZES_138 7. kerdes): a nyers INSERT
--     elrontana a V234 alkalmazas-szintu hash-lancot. A nyomon kovethetoseget ez a fajl +
--     a RAISE NOTICE kimenet + a flyway_schema_history biztositja (V244/V247/V334/V337 precedens).
--
-- VEGFELHASZNALOI INSTRUKCIO (FK-070 TBD-6 lezarasa, 2026-07-30): a korrekcio utan a nyitva
--   levo DAILY zaras-munkamenetet MEG KELL SZAKITANI es ujrainditani ("Megszakitas es
--   ujrainditas") — a Frissites gomb NEM eleg: az csak a zarasi eloellenorzest keri le ujra,
--   a bukott lepes-allapot es az elteres-tablazat kliens-oldali pillanatkep marad.
--
-- ELLENORZO SELECT (futtatas elott/utan kezzel futtathato):
--   SELECT b.code, c.code AS currency, cb.current_balance, cb.updated_at
--     FROM cash_balance cb
--     JOIN branch b   ON b.id  = cb.branch_id
--     JOIN company co ON co.id = b.company_id
--     JOIN currency c ON c.id  = cb.currency_id
--    WHERE co.code = 'EBC' AND b.code = 'BR035' AND b.is_active = TRUE
--      AND c.code IN ('EUR', 'USD')
--    ORDER BY c.code;

DO $$
DECLARE
    v_company_id UUID;
    v_branch_id UUID;
    v_eur_id BIGINT;
    v_usd_id BIGINT;
    v_rows INT;
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
        RAISE NOTICE 'V368: aktiv BR035 branch (EBC ceg) nem talalhato — nincs teendo.';
        RETURN;
    END IF;

    SELECT id INTO v_eur_id FROM currency WHERE code = 'EUR' LIMIT 1;
    SELECT id INTO v_usd_id FROM currency WHERE code = 'USD' LIMIT 1;

    IF v_eur_id IS NULL OR v_usd_id IS NULL THEN
        RAISE NOTICE 'V368: EUR/USD currency torzsadat nem talalhato — nincs teendo.';
        RETURN;
    END IF;

    -- EUR: 14334.45 -> 14334.00 (csak ha pontosan az ismert hibas ertek all benne, FR-1/FR-3)
    UPDATE cash_balance
       SET current_balance = 14334.00,
           updated_at = NOW()
     WHERE company_id = v_company_id
       AND branch_id = v_branch_id
       AND currency_id = v_eur_id
       AND current_balance = 14334.45;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows = 1 THEN
        RAISE NOTICE 'V368: BR035 EUR 14334.45 -> 14334.00, % sor korrigalva.', v_rows;
    ELSE
        RAISE NOTICE 'V368: BR035 EUR korrekcio NEM futott le (% erintett sor) — az egyenleg nem a vart 14334.45 (korabban korrigalva vagy idokozben valtozott).', v_rows;
    END IF;

    -- USD: 5797.57 -> 5797.00 (csak ha pontosan az ismert hibas ertek all benne, FR-2/FR-3)
    UPDATE cash_balance
       SET current_balance = 5797.00,
           updated_at = NOW()
     WHERE company_id = v_company_id
       AND branch_id = v_branch_id
       AND currency_id = v_usd_id
       AND current_balance = 5797.57;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows = 1 THEN
        RAISE NOTICE 'V368: BR035 USD 5797.57 -> 5797.00, % sor korrigalva.', v_rows;
    ELSE
        RAISE NOTICE 'V368: BR035 USD korrekcio NEM futott le (% erintett sor) — az egyenleg nem a vart 5797.57 (korabban korrigalva vagy idokozben valtozott).', v_rows;
    END IF;
END $$;
