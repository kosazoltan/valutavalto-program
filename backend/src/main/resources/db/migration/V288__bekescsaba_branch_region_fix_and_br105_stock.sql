-- V288: Békéscsaba-területi pénztárak `region` HELYREÁLLÍTÁSA + BR105 (Belváros 2) cash_balance-init
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
--      alatt. Ok: az Országos készlet (`/api/v1/inventory/stock` → `InventoryService.getAllStock()`) a
--      CASH_BALANCE táblát olvassa (`cashBalanceRepository.findByCompanyId`), NEM a currency_stock-ot
--      (Codex P1 review, PR #1001). Egy cash_balance-sor NÉLKÜLI aktív branch ezért SEHOL nem látszik.
--      A V250 felvette BR105-öt, de NEM hozott neki cash_balance sort. JAVÍTÁS: a BR105-nek a sibling
--      Békéscsaba pénztár(ok) valutakészletével MEGEGYEZŐ cash_balance sorokat hozunk létre 0 egyenleggel.
--      A CASHIER currency_stock sorokat a kereskedés (getOrCreateStock) hozza létre on-demand — azt itt
--      NEM kell előre seedelni. A "készlet = SUM(tranzakciók)" invariáns nem sérül (0 kezdőegyenleg).
--
-- Idempotens: IS DISTINCT FROM guard (A) + COUNT(*) early-return + ON CONFLICT DO NOTHING (B).

-- ============ A) Békéscsaba-területi branch-ek régiójának authoritatív helyreállítása ============
UPDATE branch
   SET region = 'BEKESCSABA',
       updated_at = NOW()
 WHERE company_id = (SELECT id FROM company WHERE code = 'EBC')
   AND code IN ('BR071','BR074','BR075','BR076','BR077','BR079','BR105')
   AND region IS DISTINCT FROM 'BEKESCSABA';

-- ============ B) BR105 (Békéscsaba Belváros 2) cash_balance init (0 egyenleg) ============
DO $$
DECLARE
    v_company_id   UUID;
    v_br105_id     UUID;
    v_sibling_id   UUID;
    v_existing     INT;
    v_inserted     INT;
BEGIN
    SELECT id INTO v_company_id FROM company WHERE code = 'EBC';
    IF v_company_id IS NULL THEN
        RAISE NOTICE 'V288/B: EBC cég nem található — kihagyva (alap-seed nem futott?).';
        RETURN;
    END IF;

    SELECT id INTO v_br105_id
      FROM branch
     WHERE company_id = v_company_id AND code = 'BR105';
    IF v_br105_id IS NULL THEN
        RAISE NOTICE 'V288/B: BR105 (Békéscsaba Belváros 2) nem létezik — cash_balance-init kihagyva.';
        RETURN;
    END IF;

    -- Ha BR105-nek MÁR van bármilyen cash_balance sora, nincs teendő (idempotens).
    SELECT COUNT(*) INTO v_existing
      FROM cash_balance
     WHERE branch_id = v_br105_id;
    IF v_existing > 0 THEN
        RAISE NOTICE 'V288/B: BR105 már rendelkezik % cash_balance sorral — nincs teendő.', v_existing;
        RETURN;
    END IF;

    -- A sibling Békéscsaba pénztár(ok) (BR076 -> BR074 -> BR071 -> BR077 -> BR079) valutakészlete a
    -- minta. Determinisztikus prioritás-sorrend; az ELSŐ olyan sibling, amelynek VAN cash_balance-a.
    SELECT b.id INTO v_sibling_id
      FROM branch b
     WHERE b.company_id = v_company_id
       AND b.code IN ('BR076','BR074','BR071','BR077','BR079')
       AND EXISTS (SELECT 1 FROM cash_balance cb WHERE cb.branch_id = b.id)
     ORDER BY CASE b.code
                WHEN 'BR076' THEN 1 WHEN 'BR074' THEN 2 WHEN 'BR071' THEN 3
                WHEN 'BR077' THEN 4 ELSE 5 END
     LIMIT 1;

    IF v_sibling_id IS NOT NULL THEN
        -- A sibling MINDEN valutanemére 0 egyenlegű cash_balance sor BR105-nek.
        INSERT INTO cash_balance (
            company_id, branch_id, currency_id, current_balance, opening_balance, created_at, updated_at
        )
        SELECT DISTINCT
            v_company_id, v_br105_id, cb.currency_id, 0, 0, NOW(), NOW()
          FROM cash_balance cb
         WHERE cb.branch_id = v_sibling_id
        ON CONFLICT (branch_id, currency_id) DO NOTHING;
    ELSE
        -- Fallback: ha egyetlen sibling sem rendelkezik készlettel, a magyar valutaváltó-alapkészlet
        -- (HUF + főbb devizák) 0 egyenleggel — hogy a pénztár megjelenjen a területi listában.
        INSERT INTO cash_balance (
            company_id, branch_id, currency_id, current_balance, opening_balance, created_at, updated_at
        )
        SELECT
            v_company_id, v_br105_id, cur.id, 0, 0, NOW(), NOW()
          FROM currency cur
         WHERE cur.code IN ('HUF','EUR','USD','GBP','CHF')
        ON CONFLICT (branch_id, currency_id) DO NOTHING;
    END IF;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;
    RAISE NOTICE 'V288/B: BR105 cash_balance-init — % valutanem 0 egyenleggel (sibling=%).',
        v_inserted, COALESCE(v_sibling_id::TEXT, '(fallback alapkészlet)');
END $$;

-- ============ C) BR105 vault_territory_id igazítása a Békéscsaba területhez ============
-- A `getAllStock()` territory-szűrése (territory-scoped role, pl. Békéscsaba értéktáros) a
-- `branch.vault_territory_id`-t használja (`findByCompanyIdAndVaultTerritoryId`). Ha a Békéscsaba
-- branch-eknek van vault_territory_id-juk (pl. prod-ban runtime-ban beállítva), BR105 is UGYANAZT
-- kapja (a Békéscsaba VAULT, BR075, a territory-horgony), különben egy territory-scoped Békéscsaba
-- user KIHAGYNÁ BR105-öt a cash_balance ellenére is (Codex P1, PR #1001).
-- NULL-safe + idempotens: csak akkor ír, ha BR105.vault_territory_id NULL ÉS van non-NULL sibling.
-- Ha minden Békéscsaba branch vault_territory_id-ja NULL (jelenlegi seed-állapot), ez NO-OP —
-- a központi user territoryFilter=null → BR105 a cash_balance révén (B) így is látszik.
UPDATE branch
   SET vault_territory_id = (
        SELECT b2.vault_territory_id
          FROM branch b2
         WHERE b2.company_id = branch.company_id
           AND b2.code IN ('BR075','BR076','BR074','BR071','BR077','BR079')
           AND b2.vault_territory_id IS NOT NULL
         ORDER BY CASE b2.code
                    WHEN 'BR075' THEN 1 WHEN 'BR076' THEN 2 WHEN 'BR074' THEN 3
                    WHEN 'BR071' THEN 4 WHEN 'BR077' THEN 5 ELSE 6 END
         LIMIT 1
       ),
       updated_at = NOW()
 WHERE company_id = (SELECT id FROM company WHERE code = 'EBC')
   AND code = 'BR105'
   AND vault_territory_id IS NULL
   AND EXISTS (
        SELECT 1 FROM branch b3
         WHERE b3.company_id = branch.company_id
           AND b3.code IN ('BR075','BR076','BR074','BR071','BR077','BR079')
           AND b3.vault_territory_id IS NOT NULL
   );
