-- V324 (Batch3-B / currency_stock-doc FR-5): a mar LEZART (COMPLETED) generikus
-- atadas-atvetelek netto hatasanak visszamenoleges feldolgozasa a vault
-- branch-ek currency_stock soraiba.
--
-- GYOKEROK: a generikus TransferService a cash_balance-t frissitette, a
-- currency_stock-ot SOHA — igy a vault branch-eket erinto, jovahagyott
-- mozgasok (pl. BR020 #FF000000003) a B-konyvben nem jelentek meg.
--
-- TBD-2 DONTES (dokumentalt): MIGRACIOKENT, a rendszer kezdete ota MINDEN
-- COMPLETED mozgasra. Indok: (a) determinisztikus es naplozott (NOTICE);
-- (b) a Flyway garantalja az egyszeri futast; (c) az uj kod (TransferService
-- vault-stock tukrozes) ugyanazon deploy-jal el — a migracio a boot-kor fut,
-- a friss mozgasokat mar az uj kod konyveli, atfedes nincs.
-- NEM DUPLIKAL a VaultTransferService-szel: az kulon entitason (vault_transfer)
-- dolgozik, ez a migracio kizarolag a generikus `transfer` tablat dolgozza fel.
--
-- IRANY-SZEMANTIKA (a TransferService cash-konyvelesevel 1:1 azonos):
--   F  : from -= amount (create),  to += received_amount (receive)
--   U  : from += amount (create; az atvetelnel a from-oldal a fogado)
--   UF : from -= amount, to += amount (create, azonnal COMPLETED)
--   FF : from -= amount, to -= amount (korrekcio: ketszeres kivet)
-- Sztornozott (is_cancelled=true) transzferek kihagyva — a cash-visszafordi-
-- tasuk netto 0, igy a B-konyvben sem szabad megjelenniuk.
-- Tobb-valutas lapnal a transfer_lines sorok szamitanak; egysorosnal a fejlec.
DO $$
DECLARE
    v_rows INT;
BEGIN
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
        -- Bejovo a to-oldalra (F: tenylegesen fogadott; UF: kuldott osszeg)
        SELECT company_id, to_branch_id AS branch_id, currency_id,
               CASE WHEN direction = 'F' THEN received_amount ELSE amount END AS delta
          FROM effective_lines WHERE direction IN ('F', 'UF')
        UNION ALL
        -- Bejovo a from-oldalra (U atvetel: a fogado a from-oldal)
        SELECT company_id, from_branch_id, currency_id, amount
          FROM effective_lines WHERE direction = 'U'
        UNION ALL
        -- Kimeno a from-oldalrol (F/UF/FF)
        SELECT company_id, from_branch_id, currency_id, -amount
          FROM effective_lines WHERE direction IN ('F', 'UF', 'FF')
        UNION ALL
        -- Kimeno a to-oldalrol (FF korrekcio: mindket oldal kivet)
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
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE 'V324 backfill: % (territory, valuta) sor frissitve a lezart generikus transzferek netto hatasaval.', v_rows;
END $$;
