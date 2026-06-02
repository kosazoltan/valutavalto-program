-- V288: Békéscsaba-területi pénztárak `region` HELYREÁLLÍTÁSA + BR105 (Belváros 2) készlet-init
--       (Kósa Zoltán user-direktíva, 2026-06-02 — "a Békéscsaba belvárost a szegedi területhez
--        hozza... Békéscsaba értéktárhoz Békéscsaba pénztárai tartoznak!!!").
--
-- DIAGNÓZIS (kód-alapú, prod-lekérdezés nélkül determinisztikusan helyreállítva):
--   A) Régió-drift. A `findCashierShipmentTargets` / `findVaultCounterparties` (BranchService) ÉS
--      az Országos készlet (CashierStocksPage) területi csoportosítása a `branch.region` (VARCHAR40,
--      KESZLEX nagybetűs kód) mezőn alapul. A V145-seed minden Békéscsaba-területi pénztárnak
--      'BEKESCSABA'-t adott, DE a V250 (BR105 felvétel) a régiót `region = COALESCE(branch.region,
--      EXCLUDED.region)`-nel írta — azaz ha egy sor MÁR LÉTEZETT hibás régióval (pl. 'SZEGED'), a
--      COALESCE MEGTARTOTTA a rosszat. Tünet: a Békéscsaba(-Belváros 2) a szegedi terület alá került
--      / az átadás-átvétel nem hozta a Békéscsaba pénztárt. JAVÍTÁS: a 7 Békéscsaba-területi branch
--      (Békéscsaba/Gyula/Szarvas — mind Békés megye, a BR075 Békéscsaba Értéktárhoz tartozik) régióját
--      AUTHORITATÍVAN 'BEKESCSABA'-ra állítjuk (NEM COALESCE → felülírja a hibás 'SZEGED'/NULL-t is).
--      A város→régió leképezés ténykérdés (a V145-seed + a V254 vault-besorolás megerősíti), nem becslés.
--
--   B) BR105 (Békéscsaba Belváros 2) NEM jelenik meg az Országos készletben SEM Békéscsaba, SEM Szeged
--      alatt. Ok: a CashierStocksPage branch-univerzuma KIZÁRÓLAG a `/inventory/stock` sorokból jön
--      (Codex P1 territorialis-scope döntés) — egy currency_stock-sor NÉLKÜLI branch SEHOL nem látszik.
--      A V250 felvette BR105-öt, de NEM hozott létre neki CASHIER currency_stock sort. JAVÍTÁS: a
--      BR105-nek a sibling Békéscsaba pénztár(ok) valutakészletével MEGEGYEZŐ currency_stock sorokat
--      hozunk létre 0 mennyiséggel (CASHIER, entity_id = branch.id::TEXT — VaultStockFlowService
--      konvenció). Így a "készlet = SUM(tranzakciók)" invariáns NEM sérül (0 kezdőkészlet).
--
-- Idempotens: IS DISTINCT FROM guard (A) + WHERE NOT EXISTS guard (B).

-- ============ A) Békéscsaba-területi branch-ek régiójának authoritatív helyreállítása ============
UPDATE branch
   SET region = 'BEKESCSABA',
       updated_at = NOW()
 WHERE company_id = (SELECT id FROM company WHERE code = 'EBC')
   AND code IN ('BR071','BR074','BR075','BR076','BR077','BR079','BR105')
   AND region IS DISTINCT FROM 'BEKESCSABA';

-- ============ B) BR105 (Békéscsaba Belváros 2) CASHIER currency_stock init (0 mennyiség) ============
DO $$
DECLARE
    v_company_id   UUID;
    v_br105_id     UUID;
    v_sibling_id   UUID;
    v_cur_count    INT;
    v_inserted     INT;
BEGIN
    SELECT id INTO v_company_id FROM company WHERE code = 'EBC';
    IF v_company_id IS NULL THEN
        RAISE NOTICE 'V288: EBC cég nem található — kihagyva (alap-seed nem futott?).';
        RETURN;
    END IF;

    SELECT id INTO v_br105_id
      FROM branch
     WHERE company_id = v_company_id AND code = 'BR105';
    IF v_br105_id IS NULL THEN
        RAISE NOTICE 'V288/B: BR105 (Békéscsaba Belváros 2) nem létezik — készlet-init kihagyva.';
        RETURN;
    END IF;

    -- Ha BR105-nek MÁR van bármilyen CASHIER készlet-sora, nincs teendő (idempotens).
    SELECT COUNT(*) INTO v_cur_count
      FROM currency_stock
     WHERE company_id = v_company_id
       AND entity_type = 'CASHIER'
       AND entity_id = v_br105_id::TEXT;
    IF v_cur_count > 0 THEN
        RAISE NOTICE 'V288/B: BR105 már rendelkezik % CASHIER készlet-sorral — nincs teendő.', v_cur_count;
        RETURN;
    END IF;

    -- A sibling Békéscsaba pénztár(ok) (BR076 -> BR074 -> BR071 -> BR077 -> BR079) valutakészlete a
    -- minta. Determinisztikus prioritás-sorrend; az ELSŐ olyan sibling, amelynek VAN CASHIER készlete.
    SELECT b.id INTO v_sibling_id
      FROM branch b
     WHERE b.company_id = v_company_id
       AND b.code IN ('BR076','BR074','BR071','BR077','BR079')
       AND EXISTS (
            SELECT 1 FROM currency_stock cs
             WHERE cs.company_id = v_company_id
               AND cs.entity_type = 'CASHIER'
               AND cs.entity_id = b.id::TEXT
       )
     ORDER BY CASE b.code
                WHEN 'BR076' THEN 1 WHEN 'BR074' THEN 2 WHEN 'BR071' THEN 3
                WHEN 'BR077' THEN 4 ELSE 5 END
     LIMIT 1;

    IF v_sibling_id IS NOT NULL THEN
        -- A sibling valutakészletének MINDEN valutanemére 0 mennyiségű sor BR105-nek.
        INSERT INTO currency_stock (
            company_id, entity_type, entity_id, currency_code,
            quantity, weighted_avg_cost, last_updated
        )
        SELECT DISTINCT
            v_company_id, 'CASHIER', v_br105_id::TEXT, cs.currency_code,
            0,
            CASE WHEN cs.currency_code = 'HUF' THEN 1.0 ELSE 0 END,
            NOW()
          FROM currency_stock cs
         WHERE cs.company_id = v_company_id
           AND cs.entity_type = 'CASHIER'
           AND cs.entity_id = v_sibling_id::TEXT;
    ELSE
        -- Fallback: ha egyetlen sibling sem rendelkezik készlettel, a magyar valutaváltó-alapkészlet
        -- (HUF + főbb devizák) 0 mennyiséggel — hogy a pénztár megjelenjen a területi listában.
        INSERT INTO currency_stock (
            company_id, entity_type, entity_id, currency_code,
            quantity, weighted_avg_cost, last_updated
        )
        SELECT
            v_company_id, 'CASHIER', v_br105_id::TEXT, c.code,
            0,
            CASE WHEN c.code = 'HUF' THEN 1.0 ELSE 0 END,
            NOW()
          FROM (VALUES ('HUF'), ('EUR'), ('USD'), ('GBP'), ('CHF')) AS c(code);
    END IF;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;
    RAISE NOTICE 'V288/B: BR105 CASHIER készlet-init — % valutanem 0 mennyiséggel (sibling=%).',
        v_inserted, COALESCE(v_sibling_id::TEXT, '(fallback alapkészlet)');
END $$;
