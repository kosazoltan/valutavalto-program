-- V370: FKH-028 Fazis 5 — BR035 penztar USD-keszletenek +1000 USD visszairasa
-- (a duplikalt AT-000009/AT-000010 atadas es AA035100002/AA035100003
-- ellentranzakcioik rendezese: egyenleg-korrekcio + megjeloles).
--
-- GYOKEROK: az FKH-028-ban dokumentalt dupla-bekuldes (frontend loading-ablak +
-- backend idempotencia-hiany, ebben a korban javitva) ketszer konyvelte le ugyanazt
-- az 1000 USD-s atadast a BR035 penztarbol — a keszlet 1000 USD-vel kevesebbet mutat.
--
-- KORREKCIO:
--   (1) BR035 USD cash_balance += 1000.00 — a Flyway once-only szemantikajan TUL a
--       transfer-annotacio (lasd (2)) "mar alkalmazva" markerkent is vedi: ha az
--       AT-000009 mar jelolt, a +1000 NEM fut le ujra (NFR-idempotencia kezi
--       ujrafuttatasnal is); a NOTICE a korabbi es az uj erteket is kiirja.
--   (2) A negy erintett bizonylat notes-mezoje jelolest kap ("[FKH-028 V370] duplikalt
--       tetel — az egyenleg-korrekcio a V370 migracioban rendezve"). SZANDEKOSAN nem
--       storno es nem statusz-valtas: az alkalmazas-szintu sztorno a Fazis 3 utan a
--       cash_balance-t IS visszairna, ami az (1) korrekcioval EGYUTT DUPLA jovairas
--       lenne. FIGYELEM AZ UZEMELTETONEK/FELHASZNALONAK: az AT-000009/AT-000010
--       tetelekre a V370 utan TILOS app-szintu sztornot inditani!
--
-- SCOPE / BIZTONSAG:
--   - Fiok-feloldas kizarolag kodos lookuppal (BR035 + EBC + is_active), a V368 mintajara.
--   - A notes-UPDATE csak a pontos bizonylatszamokra, cegszuressel, es csak ha a jeloles
--     meg nincs benne (LIKE-guard) — ketszeri futasnal sem duplazza a szoveget.
--   - SZANDEKOSAN NINCS audit_log INSERT (V234 hash-lanc vedelme, V368 precedens).
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
    v_branch_id UUID;
    v_usd_id BIGINT;
    v_before NUMERIC;
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
        RAISE NOTICE 'V370: aktiv BR035 branch (EBC ceg) nem talalhato — nincs teendo.';
        RETURN;
    END IF;

    SELECT id INTO v_usd_id FROM currency WHERE code = 'USD' LIMIT 1;
    IF v_usd_id IS NULL THEN
        RAISE NOTICE 'V370: USD currency torzsadat nem talalhato — nincs teendo.';
        RETURN;
    END IF;

    SELECT current_balance INTO v_before
      FROM cash_balance
     WHERE company_id = v_company_id AND branch_id = v_branch_id AND currency_id = v_usd_id;

    IF EXISTS (SELECT 1 FROM transfer
                WHERE company_id = v_company_id
                  AND transfer_number = 'AT-000009'
                  AND notes LIKE '%[FKH-028 V370]%') THEN
        RAISE NOTICE 'V370: a korrekcio mar alkalmazva (AT-000009 jelolt) — a +1000 USD NEM fut le ujra.';
    ELSIF v_before IS NULL THEN
        RAISE NOTICE 'V370: BR035 USD cash_balance sor nem letezik — a korrekcio NEM futott le (kezi vizsgalat szukseges).';
    ELSE
        UPDATE cash_balance
           SET current_balance = current_balance + 1000.00,
               updated_at = NOW()
         WHERE company_id = v_company_id AND branch_id = v_branch_id AND currency_id = v_usd_id;
        RAISE NOTICE 'V370: BR035 USD % -> % (+1000.00, duplikalt atadas visszairasa).',
            v_before, v_before + 1000.00;
    END IF;

    -- (2) A duplikalt atadolapok megjelolese (transfer.notes)
    UPDATE transfer
       SET notes = COALESCE(notes || ' ', '')
                   || '[FKH-028 V370] duplikalt tetel — az egyenleg-korrekcio a V370 migracioban rendezve; app-szintu sztorno TILOS ra.'
     WHERE company_id = v_company_id
       AND transfer_number IN ('AT-000009', 'AT-000010')
       AND (notes IS NULL OR notes NOT LIKE '%[FKH-028 V370]%');
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE 'V370: % transfer (AT-000009/AT-000010) megjelolve.', v_rows;

    -- (2b) A duplikalt ellentranzakciok megjelolese (transaction.notes)
    UPDATE transaction
       SET notes = COALESCE(notes || ' ', '')
                   || '[FKH-028 V370] duplikalt tetel — az egyenleg-korrekcio a V370 migracioban rendezve; app-szintu sztorno TILOS ra.'
     WHERE branch_id = v_branch_id
       AND receipt_number IN ('AA035100002', 'AA035100003')
       AND (notes IS NULL OR notes NOT LIKE '%[FKH-028 V370]%');
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE 'V370: % transaction (AA035100002/AA035100003) megjelolve.', v_rows;
END $$;
