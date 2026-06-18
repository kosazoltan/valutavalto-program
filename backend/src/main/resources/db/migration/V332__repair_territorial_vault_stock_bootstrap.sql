-- V332: territorial vault currency_stock bootstrap repair
--
-- VERIFIED ROOT CAUSES FROM REPO:
-- 1) V326 created the late territorial vault_territory rows, but unlike V159 it only
--    seeded 0-valued currency_stock rows. For territorial HUF rows this skipped the
--    base_capital-backed initialization completely.
-- 2) V323 explicitly documented that late-created FX rows start from synthetic opening=0.
--    If V324/V326 backfill yields a negative FX balance on that synthetic zero opening,
--    the negative value is not a trustworthy opening-fact reconstruction; it is only a
--    bootstrap artifact from the fallback basis.
--
-- Repair scope (idempotent, checksum-safe as new migration):
-- - Territorial HUF VAULT rows with WAC=0 (V326 bootstrap signature) get the missing
--   base_capital added once and HUF WAC normalized to 1 (V159 convention).
-- - Territorial non-HUF VAULT rows with WAC=0 and negative quantity are clamped to 0,
--   because these rows originate from the synthetic V323 zero-opening bootstrap and the
--   repo does not have authoritative historical FX opening stock to support a negative
--   reconstructed current balance on that basis.
--
-- The default "Fo Ertektar" territory is excluded: it was seeded earlier by V156/V159
-- and does not belong to the V326 late-territory repair set.
DO $$
DECLARE
    v_huf_fixed INT;
    v_fx_clamped INT;
BEGIN
    UPDATE currency_stock cs
       SET quantity = cs.quantity + vt.base_capital,
           weighted_avg_cost = 1.0,
           last_updated = NOW()
      FROM vault_territory vt
     WHERE cs.company_id = vt.company_id
       AND cs.entity_type = 'VAULT'
       AND cs.entity_id = vt.id::TEXT
       AND cs.currency_code = 'HUF'
       AND vt.is_active = TRUE
       AND vt.name <> 'Fo Ertektar'
       AND COALESCE(cs.weighted_avg_cost, 0) = 0;
    GET DIAGNOSTICS v_huf_fixed = ROW_COUNT;

    UPDATE currency_stock cs
       SET quantity = 0,
           last_updated = NOW()
      FROM vault_territory vt
     WHERE cs.company_id = vt.company_id
       AND cs.entity_type = 'VAULT'
       AND cs.entity_id = vt.id::TEXT
       AND cs.currency_code <> 'HUF'
       AND vt.is_active = TRUE
       AND vt.name <> 'Fo Ertektar'
       AND COALESCE(cs.weighted_avg_cost, 0) = 0
       AND cs.quantity < 0;
    GET DIAGNOSTICS v_fx_clamped = ROW_COUNT;

    RAISE NOTICE 'V332/1: % territorial HUF VAULT row repaired with missing base_capital init.', v_huf_fixed;
    RAISE NOTICE 'V332/2: % territorial FX VAULT row clamped from synthetic negative bootstrap to 0.', v_fx_clamped;
END $$;
