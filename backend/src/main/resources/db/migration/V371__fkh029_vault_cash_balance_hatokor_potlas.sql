-- V371: FKH-029 FR-1 — az ERTEKTARI cash_balance sorok hatokor-teljesitese.
-- MINDEN aktiv, is_vault=TRUE branch MINDEN aktiv valutajara, 0 nyitoertekkel, MINDEN cegre.
--
-- GYOKEROK / KONTEXTUS:
--   A V334 (FK-036, 2026-06-20) az AKKORI invarians alapjan ("ertektar branch-nek nem szabad
--   cash_balance sora legyen") DINAMIKUSAN torolte MINDEN EBC-s, aktiv, is_vault=TRUE branch
--   cash_balance sorait. Ezt az invarianst a Batch3-B "mirror" architektura FELULIRTA: a
--   TransferService a vault-erintett mozgasokat a cash_balance-on konyveli, es onnan tukrozi
--   a currency_stock-ba (applyVaultStockMirror); az increase/decreaseCashBalance hianyzo sornal
--   "Kassza egyenleg nem talalhato" ValidationException-nel bukik.
--
--   A V369 (FKH-028 Fazis 4, 2026-08-04) ezt CSAK a BR020-ra javitotta, mert akkor nem volt
--   futtathato read-only prod-lekerdezo mechanizmus a tobbi Ertektar hatokorenek ellenorzesehez
--   (FKH-028 FR-5, tudatos scope-kivetel). Az elo audit (2026-08-04) elkeszult:
--
--     branch | cash_balance sorok | beerkezo transfer
--     -------+--------------------+------------------
--     BR010  |  0                 |  0
--     BR020  | 23  (V369)         |  7
--     BR040  |  0                 |  0
--     BR050  |  0                 |  0
--     BR063  |  0                 |  0
--     BR075  |  0                 | 10  <-- 10 PENDING atadas 2026-05-26 OTA BERAGADVA
--     BR120  |  0                 |  0
--     BR145  |  0                 |  0
--
--   Mind a 8 Ertektarnak van 23 VAULT currency_stock sora (a keszlet-oldal rendben van);
--   kizarolag a KONYVELESI (cash_balance) oldal hianyzik. A BR075 Bekescsaba Ertektar
--   10 atadasa (3x 10 000 000 HUF, 32 000 EUR, 20 USD) ezert nem jovahagyhato.
--
-- SCOPE / BIZTONSAG:
--   - MINDEN ceg (nem csak EBC): a cash_balance.company_id a branch.company_id-bol jon,
--     igy a multi-tenant izolacio szerkezetileg garantalt (nincs hardkodolt cegkod).
--   - Csak AKTIV (is_active=TRUE) es is_vault=TRUE branch — a V334 torlesi predikatumanak
--     pontos tukorkepe, igy a hatokor bizonyithatoan azonos.
--   - Csak AKTIV valutakra (currency.is_active=TRUE).
--   - CSAK a HIANYZO (branch, valuta) parokra szurt INSERT (NOT EXISTS) — meglevo sort NEM
--     modosit, sem az erteket, sem az updated_at-jat. A BR020 V369-ben potolt 23 sora
--     ERINTETLEN. Idempotens: masodik futas 0 sort ir.
--   - 0 nyitoertek: az Ertektaraknak nincs valos fizikai "kassza"-keszlete; a tenyleges
--     keszlet a currency_stock/vault_territory utvonalon el. A cash_balance itt KONYVELESI
--     reteg (V369 dontes), ezert 0-rol indul.
--   - SZANDEKOSAN NINCS audit_log INSERT (V368/V369 precedens: a nyers INSERT elrontana a
--     V234 hash-lancot); a nyomon kovetes: ez a fajl + RAISE NOTICE + flyway_schema_history.
--   - A megjelenitesi vedohalo ERINTETLEN: az InventoryService.getAllStock
--     activeNonVaultBranch predikatuma (FK-036) tovabbra is kiszuri a vault-branchet az
--     Orszagos keszlet nezetbol. A TreasuryDashboardService szurojet az FKH-029 FR-6 adja.
--
-- ELVART HATAS PRODON (Gate A 2026-08-04T19:08Z alapjan): 7 branch x 23 aktiv valuta = 161 uj sor.
--
-- ELLENORZO SELECT (elotte/utana):
--   SELECT b.code, count(cb.id) AS cash_balance_rows,
--          count(cb.id) FILTER (WHERE cb.current_balance <> 0) AS nonzero
--     FROM branch b
--     LEFT JOIN cash_balance cb ON cb.branch_id = b.id
--    WHERE b.is_vault = TRUE AND b.is_active = TRUE
--    GROUP BY b.code ORDER BY b.code;

DO $$
DECLARE
    v_branch RECORD;
    v_rows INT;
    v_total INT := 0;
    v_branches INT := 0;
BEGIN
    FOR v_branch IN
        SELECT b.id, b.code, b.company_id
          FROM branch b
         WHERE b.is_vault = TRUE
           AND b.is_active = TRUE
         ORDER BY b.code
    LOOP
        INSERT INTO cash_balance (company_id, branch_id, currency_id, current_balance,
                                  opening_balance, created_at, updated_at, version)
        SELECT v_branch.company_id, v_branch.id, c.id, 0, 0, NOW(), NOW(), 0
          FROM currency c
         WHERE c.is_active = TRUE
           AND NOT EXISTS (
               SELECT 1 FROM cash_balance cb
                WHERE cb.branch_id = v_branch.id
                  AND cb.currency_id = c.id
           );
        GET DIAGNOSTICS v_rows = ROW_COUNT;

        v_total := v_total + v_rows;
        v_branches := v_branches + 1;
        RAISE NOTICE 'V371: % — % hianyzo cash_balance sor potolva 0 nyitoertekkel.',
            v_branch.code, v_rows;
    END LOOP;

    IF v_branches = 0 THEN
        RAISE NOTICE 'V371: nincs aktiv is_vault=TRUE branch — nincs teendo.';
    ELSE
        RAISE NOTICE 'V371: osszesen % hianyzo cash_balance sor potolva % ertektari branch-en.',
            v_total, v_branches;
    END IF;
END $$;
