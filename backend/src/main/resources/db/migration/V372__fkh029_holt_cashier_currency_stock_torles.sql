-- V372: FKH-029 FR-5 — a HOLT CASHIER currency_stock sorok torlese.
--
-- GYOKEROK / KONTEXTUS:
--   A currency_stock tabla ket entitas-tipust tart nyilvan:
--     entity_type='VAULT'   -> entity_id = vault_territory_id  (ELO, helyesen mukodo reteg)
--     entity_type='CASHIER' -> entity_id = branch UUID         (HOLT reteg)
--
--   Az elo audit (2026-08-04, Hetzner prod, read-only) szerint a CASHIER reteg allapota:
--
--     branch          | aktiv | valuta | currency_stock | cash_balance | last_updated
--     ----------------+-------+--------+----------------+--------------+-------------
--     KORUT (Korut)   | FALSE | EUR    |  5 200         | 0,00         | 2026-03-16
--     KORUT           | FALSE | USD    |  4 100         | 0,00         | 2026-03-16
--     TISZA (T.Sarok) | FALSE | EUR    |  8 500         | 0,00         | 2026-03-16
--     TISZA           | FALSE | USD    |  6 000         | 0,00         | 2026-03-16
--
--   Osszesen 4 sor, MIND INAKTIV fiokon, azonos 2026-03-16-i idobelyeggel (seed-adat).
--   Az ELO fiokoknak (pl. BR035) egyetlen CASHIER soruk sincs. A reteget taplalo EGYETLEN
--   irasi utvonal (MaterialReceiptService.finalizeReceipt) soha nem futott elesben:
--   a material_receipt tabla 0 sor. A ket olvaso (DailyBalanceService Szint-3 nyito-fallback,
--   MonthlyClosingService WAC-bontas) ezert elo fiokra MINDIG csendben 0-ra esett.
--
--   FKH-029 dontes (TBD-3): KIVEZETES. Az aktivalas (mirror-iras CASHIER-re) a WacService
--   sajat kommentje szerint elesites elott "a nyito-keszlet bekerulesi aranak konzisztenciajat
--   ops/compliance igazolja" — 27 valuta x ~90 iroda visszamenoleges rekonstrukcioja, onallo
--   fejlesztes. A WAC_PROFIT_TRACKING_ENABLED flag default OFF.
--
-- SCOPE / BIZTONSAG — HARMAS vedelem, hogy elo adat SEMMIKEPP ne torlodjon:
--   1. entity_type = 'CASHIER'  (a VAULT reteg 207 sora ERINTETLEN)
--   2. a sorhoz tartozo branch INAKTIV (is_active = FALSE) — elo fiok sora nem torlodik
--   3. a sorhoz tartozo (branch, valuta) cash_balance NULLA vagy NEM LETEZIK — barmilyen
--      konyvelesi egyenleggel biro par erintetlen marad
--   4. last_updated < '2026-04-01' — a 2026-03-16-i seed-generacio; ennel ujabb (tehat
--      esetleg valodi uzemi) sor nem torlodik
--   Ha barmelyik feltetel nem all, a sor MEGMARAD. Idempotens: masodik futas 0 sort torol.
--
--   SZANDEKOSAN NINCS audit_log INSERT (V368/V369/V371 precedens: a nyers INSERT elrontana
--   a V234 hash-lancot); nyomon kovetes: ez a fajl + RAISE NOTICE + flyway_schema_history.
--
--   A tabla, az entity_type='VAULT' sorok, a CurrencyStock entitas es a repository-metodusok
--   VALTOZATLANOK — ez kizarolag adat-takaritas. A kod-szintu kivezetes (DailyBalanceService
--   Szint-3 -> cash_balance) az FKH-029 FR-5 kod-resze.
--
-- ELVART HATAS PRODON: 4 sor torolve; a VAULT reteg 207 sora valtozatlan.
--
-- ELLENORZO SELECT (elotte/utana):
--   SELECT entity_type, count(*) FROM currency_stock GROUP BY entity_type ORDER BY 1;

DO $$
DECLARE
    v_rows INT;
BEGIN
    DELETE FROM currency_stock cs
     WHERE cs.entity_type = 'CASHIER'
       AND cs.last_updated IS NOT NULL
       AND cs.last_updated < TIMESTAMP '2026-04-01 00:00:00'
       -- A sor branch-e letezik ES inaktiv (elo fiok sorat nem bantjuk).
       AND EXISTS (
           SELECT 1
             FROM branch b
            WHERE b.id::text = cs.entity_id
              AND b.is_active = FALSE
       )
       -- A (branch, valuta) parhoz nincs NEM-NULLA cash_balance (konyvelesi egyenleg).
       AND NOT EXISTS (
           SELECT 1
             FROM cash_balance cb
             JOIN currency c ON c.id = cb.currency_id
            WHERE cb.branch_id::text = cs.entity_id
              AND c.code = cs.currency_code
              AND cb.current_balance <> 0
       );
    GET DIAGNOSTICS v_rows = ROW_COUNT;

    RAISE NOTICE 'V372: % holt CASHIER currency_stock sor torolve (inaktiv fiok, nulla cash_balance, 2026-04-01 elotti seed).', v_rows;
END $$;
