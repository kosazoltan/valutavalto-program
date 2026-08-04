-- V369: FKH-028 Fazis 4 — BR020 "Szeged Ertektar" hianyzo cash_balance sorainak potlasa
-- MINDEN aktiv valutara, 0 nyitoertekkel.
--
-- GYOKEROK / KONTEXTUS:
--   A V334 (FK-036, 2026-06-20) az AKKORI invarians alapjan ("ertektar branch-nek nem
--   szabad cash_balance sora legyen") TOROLTE a BR020 cash_balance sorait. Ezt az
--   invarianst azota a Batch3-B "mirror" architektura FELULIRTA: a TransferService a
--   vault-erintett mozgasokat a cash_balance-on konyveli, es onnan tukrozi a
--   currency_stock-ba (TransferService.applyVaultStockMirror; increase/decreaseCashBalance
--   pedig orElseThrow-val bukik hianyzo sornal: "Kassza egyenleg nem talalhato").
--   Emiatt a BR020-t erinto Transfer-jovahagyas ma hibara fut. Az FKH-028 (Ertektari
--   oldal, kritikai review-n atment) dontese: a cash_balance sor a KONYVELESI reteg,
--   vault-branchnel is leteznie kell — 0 nyitoertekkel, mert a BR020-nak sosem volt
--   valos fizikai keszlete (a V247-korszak ~220M HUF maradvanya figyelmen kivul
--   hagyando; azt a V334 helyesen torolte).
--
-- SCOPE / BIZTONSAG:
--   - KIZAROLAG a BR020 (company.code='EBC', is_active=TRUE) branch — az FR-5 szerinti
--     tobbi Ertektar hatokor-ellenorzese kulon follow-up (read-only prod-lekerdezo
--     mechanizmus hianyaban ebbol a korbol tudatosan kimaradt).
--   - CSAK a HIANYZO (branch, valuta) parokra szurt INSERT — meglevo sort NEM modosit,
--     igy barmilyen idokozbeni valtozas erintetlen marad. Idempotens (NOT EXISTS).
--   - Csak AKTIV valutakra (currency.is_active=TRUE).
--   - SZANDEKOSAN NINCS audit_log INSERT (V368 precedens: a nyers INSERT elrontana a
--     V234 hash-lancot); a nyomon kovetes: ez a fajl + RAISE NOTICE + flyway_schema_history.
--
-- ELLENORZO SELECT (elotte/utana):
--   SELECT c.code, cb.current_balance
--     FROM currency c
--     LEFT JOIN cash_balance cb
--       ON cb.currency_id = c.id
--      AND cb.branch_id = (SELECT b.id FROM branch b JOIN company co ON co.id=b.company_id
--                          WHERE b.code='BR020' AND co.code='EBC' AND b.is_active=TRUE LIMIT 1)
--    WHERE c.is_active = TRUE
--    ORDER BY c.code;

DO $$
DECLARE
    v_company_id UUID;
    v_branch_id UUID;
    v_rows INT;
BEGIN
    SELECT b.id, b.company_id
      INTO v_branch_id, v_company_id
      FROM branch b
      JOIN company co ON co.id = b.company_id
     WHERE b.code = 'BR020'
       AND co.code = 'EBC'
       AND b.is_active = TRUE
     LIMIT 1;

    IF v_branch_id IS NULL THEN
        RAISE NOTICE 'V369: aktiv BR020 branch (EBC ceg) nem talalhato — nincs teendo.';
        RETURN;
    END IF;

    INSERT INTO cash_balance (company_id, branch_id, currency_id, current_balance,
                              opening_balance, created_at, updated_at)
    SELECT v_company_id, v_branch_id, c.id, 0, 0, NOW(), NOW()
      FROM currency c
     WHERE c.is_active = TRUE
       AND NOT EXISTS (
           SELECT 1 FROM cash_balance cb
            WHERE cb.branch_id = v_branch_id
              AND cb.currency_id = c.id
       );
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE 'V369: BR020 — % hianyzo cash_balance sor potolva 0 nyitoertekkel.', v_rows;
END $$;
