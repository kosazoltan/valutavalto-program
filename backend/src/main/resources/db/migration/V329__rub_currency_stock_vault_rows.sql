-- V329: hianyzo RUB deviza-sorok potlasa a currency_stock tablaban minden
-- aktiv vault_territory-hoz.
--
-- GYOKER: a V323 (currency_stock deviza-sor backfill) CSAK aktiv valutakra
-- seedelt (c.is_active = TRUE), a RUB pedig a V319 ota inaktiv volt — igy a RUB
-- kimaradt. A V327 visszaaktivalta a RUB-ot, enelkul viszont az "Ertektari
-- keszlet" nezet RUB-ra ures maradna.
--
-- A V323 mintaja: nyitoertek 0, WAC 0 (a tenyleges allapot a jovobeni
-- mozgasokbol epul — historikus bekerulesi ar nem rekonstrualhato).
-- Idempotens: a V159/V323 NOT EXISTS guard-mintajaval. company_id kotelezo (§1).
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
    WHERE vt.is_active = TRUE
      AND c.code = 'RUB'
      AND c.is_active = TRUE
      AND NOT EXISTS (
          SELECT 1 FROM currency_stock cs
          WHERE cs.company_id = vt.company_id
            AND cs.entity_type = 'VAULT'
            AND cs.entity_id = vt.id::TEXT
            AND cs.currency_code = c.code
      );
    GET DIAGNOSTICS v_inserted = ROW_COUNT;
    RAISE NOTICE 'V329: % uj RUB VAULT currency_stock sor letrehozva (qty=0, wac=0).', v_inserted;
END $$;
