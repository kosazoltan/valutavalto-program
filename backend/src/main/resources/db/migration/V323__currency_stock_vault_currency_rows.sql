-- V323 (Batch3-B / currency_stock-doc FR-4): hianyzo deviza-sorok potlasa a
-- currency_stock tablaban minden aktiv vault_territory-hoz.
--
-- GYOKEROK: a V159 KIZAROLAG HUF sorokat seedelt (base_capital nyitoertekkel);
-- deviza-sor csak vault-modulos mozgasnal (getOrCreateStock) keletkezett volna,
-- a generikus transfer-utvonal pedig sosem irt currency_stock-ot — ezert az
-- "Ertektari keszlet" nezet devizara ures volt.
--
-- TBD-1 DONTES (dokumentalt): a nyitoertek 0, WAC 0 — a tenyleges allapotot a
-- V324-es backfill (lezart mozgasok netto hatasa) allitja be; nyitoerteket nem
-- talalunk ki. A WAC a jovobeni mozgasokbol epul (a historikus bekerulesi ar
-- nem rekonstrualhato tenyadatbol).
--
-- Valuta-kor: az AKTIV valutak (a RUB a V319 ota inaktiv — kimarad), a
-- VaultStockFlowService.getOrCreateStock defaultjaival (quantity=0, wac=0)
-- es a V159 NOT EXISTS guard-mintajaval (idempotens). company_id kotelezo (§1).
DO $$
DECLARE
    v_inserted INT;
BEGIN
    INSERT INTO currency_stock (
        company_id, entity_type, entity_id, currency_code,
        quantity, weighted_avg_cost, last_updated
    )
    SELECT
        vt.company_id, 'VAULT', vt.id::TEXT, c.code,
        0, 0, NOW()
    FROM vault_territory vt
    CROSS JOIN currency c
    WHERE vt.active = TRUE
      AND c.is_active = TRUE
      AND NOT EXISTS (
          SELECT 1 FROM currency_stock cs
          WHERE cs.company_id = vt.company_id
            AND cs.entity_type = 'VAULT'
            AND cs.entity_id = vt.id::TEXT
            AND cs.currency_code = c.code
      );
    GET DIAGNOSTICS v_inserted = ROW_COUNT;
    RAISE NOTICE 'V323: % uj VAULT currency_stock sor letrehozva (qty=0, wac=0).', v_inserted;
END $$;
