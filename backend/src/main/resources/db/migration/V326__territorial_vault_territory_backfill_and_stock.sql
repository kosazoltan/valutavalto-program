-- V326 (currency_stock-doc utan / elo-DB diagnozis 2026-06-14): a 8 TERULETI
-- vault_territory potlasa + branch-hozzarendeles + currency_stock seed/backfill.
--
-- GYOKEROK (elo Neon prod diagnozis, 2026-06-14): a vault_territory tablaban
-- KIZAROLAG a "Fo Ertektar" sor letezett — a V60-as 8-teruletes seed 0 sort
-- hozott, mert a `SELECT id FROM company LIMIT 1` a V60 futasakor ures company
-- tablan 0 sort adott (az INSERT ... SELECT ... FROM company semmit sem szurt be).
-- Emiatt a V322 nev-match (vt.name = TRIM(REPLACE(b.name,'Értéktár',''))) egyetlen
-- teruleti ertektar branch-hez sem talalt territory-t -> mind a 8 (BR010 Szekszard,
-- BR020 Szeged, ... BR145 Kaposvar) vault_territory_id-ja NULL maradt, ezert a
-- V323/V324 kihagyta oket, es az "Ertektari keszlet" nezet ezekre ures/0 volt.
--
-- JAVITAS (idempotens, a V60/V322/V323/V324 mintait koveti):
--   1) a 8 teruleti vault_territory potlasa (V60 ertekek, EBC company), ON CONFLICT skip
--   2) branch.vault_territory_id kitoltes (V322 nev-match logika)
--   3) currency_stock 0-s sorok az uj territory-kra (V323 NOT EXISTS guard)
--   4) a lezart generikus transzferek netto hatasanak backfillje (V324 logika)
--      a most mar kitoltott vault_territory_id-kkal — a "Fo Ertektar"-t nem erinti
--      (ahhoz nem kotodik branch), igy nincs duplikacio.
DO $$
DECLARE
    v_terr INT;
    v_branch INT;
    v_seed INT;
    v_backfill INT;
BEGIN
    -- 1) 8 teruleti vault_territory potlasa (V60 alaptoke-ertekek).
    INSERT INTO vault_territory (company_id, name, base_capital, base_capital_approved_at, is_active)
    SELECT c.id, t.name, t.cap, DATE '2025-12-15', TRUE
      FROM company c
      CROSS JOIN (VALUES
          ('Békéscsaba', 165000000), ('Nyíregyháza', 250000000), ('Szeged', 220000000),
          ('Kaposvár', 250000000), ('Debrecen', 305000000), ('Kecskemét', 220000000),
          ('Pécs', 195000000), ('Szekszárd', 195000000)
      ) AS t(name, cap)
     WHERE c.code = 'EBC'
    ON CONFLICT (company_id, name) DO NOTHING;
    GET DIAGNOSTICS v_terr = ROW_COUNT;
    RAISE NOTICE 'V326/1: % teruleti vault_territory letrehozva.', v_terr;

    -- 2) branch.vault_territory_id kitoltes (V322 nev-match).
    UPDATE branch b
       SET vault_territory_id = vt.id,
           updated_at = NOW()
      FROM vault_territory vt
     WHERE b.is_vault = TRUE
       AND b.vault_territory_id IS NULL
       AND vt.company_id = b.company_id
       AND vt.is_active = TRUE
       AND vt.name = TRIM(REPLACE(b.name, 'Értéktár', ''));
    GET DIAGNOSTICS v_branch = ROW_COUNT;
    RAISE NOTICE 'V326/2: % vault branch vault_territory_id kitoltve.', v_branch;

    -- 3) currency_stock 0-s sorok az uj territory-kra (V323 NOT EXISTS guard).
    INSERT INTO currency_stock (
        company_id, entity_type, entity_id, currency_code,
        quantity, weighted_avg_cost, last_updated
    )
    SELECT vt.company_id, 'VAULT', vt.id::TEXT, c.code, 0, 0, NOW()
      FROM vault_territory vt
      CROSS JOIN currency c
     WHERE vt.is_active = TRUE
       AND c.is_active = TRUE
       AND NOT EXISTS (
           SELECT 1 FROM currency_stock cs
            WHERE cs.company_id = vt.company_id
              AND cs.entity_type = 'VAULT'
              AND cs.entity_id = vt.id::TEXT
              AND cs.currency_code = c.code
       );
    GET DIAGNOSTICS v_seed = ROW_COUNT;
    RAISE NOTICE 'V326/3: % currency_stock 0-s sor potolva.', v_seed;

    -- 4) lezart generikus transzferek netto backfillje (V324 logika), most mar a
    --    kitoltott vault_territory_id-kkal. Idempotens: ON CONFLICT += , de a 8 uj
    --    territory-ra a V324 eredetileg nem futott (NULL volt), igy nincs duplikacio.
    WITH effective_lines AS (
        SELECT
            t.company_id,
            t.from_branch_id,
            t.to_branch_id,
            COALESCE(t.direction, 'UF') AS direction,
            COALESCE(tl.currency_id, t.currency_id) AS currency_id,
            COALESCE(tl.amount, t.amount) AS amount,
            COALESCE(tl.received_amount, t.received_amount, tl.amount, t.amount) AS received_amount
        FROM transfer t
        LEFT JOIN transfer_lines tl ON tl.transfer_id = t.id
        WHERE t.status = 'COMPLETED'
          AND COALESCE(t.is_cancelled, FALSE) = FALSE
    ),
    deltas AS (
        SELECT company_id, to_branch_id AS branch_id, currency_id,
               CASE WHEN direction = 'F' THEN received_amount ELSE amount END AS delta
          FROM effective_lines WHERE direction IN ('F', 'UF')
        UNION ALL
        SELECT company_id, from_branch_id, currency_id, amount
          FROM effective_lines WHERE direction = 'U'
        UNION ALL
        SELECT company_id, from_branch_id, currency_id, -amount
          FROM effective_lines WHERE direction IN ('F', 'UF', 'FF')
        UNION ALL
        SELECT company_id, to_branch_id, currency_id, -amount
          FROM effective_lines WHERE direction = 'FF'
    ),
    vault_net AS (
        SELECT d.company_id,
               b.vault_territory_id,
               c.code AS currency_code,
               SUM(d.delta) AS net
          FROM deltas d
          JOIN branch b ON b.id = d.branch_id AND b.is_vault = TRUE AND b.vault_territory_id IS NOT NULL
          JOIN currency c ON c.id = d.currency_id
         GROUP BY d.company_id, b.vault_territory_id, c.code
        HAVING SUM(d.delta) <> 0
    )
    INSERT INTO currency_stock (
        company_id, entity_type, entity_id, currency_code,
        quantity, weighted_avg_cost, last_updated
    )
    SELECT vn.company_id, 'VAULT', vn.vault_territory_id::TEXT, vn.currency_code,
           vn.net, 0, NOW()
      FROM vault_net vn
    ON CONFLICT (company_id, entity_type, entity_id, currency_code)
    DO UPDATE SET
        quantity = currency_stock.quantity + EXCLUDED.quantity,
        last_updated = NOW();
    GET DIAGNOSTICS v_backfill = ROW_COUNT;
    RAISE NOTICE 'V326/4: % currency_stock sor backfillelve a lezart transzferek netto hatasaval.', v_backfill;
END $$;
