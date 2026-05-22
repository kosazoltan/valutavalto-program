-- ============================================================================
-- V257 (G3, EXCMD b2-zaras-ablak FR-13): zárás-eltérés audit-mezők
-- A ClosingWizard véglegesítésekor mért pénzügyi eltérés (címletezett − várt) és
-- a hozzá megadott magyarázat (eltérés-gate). Additív, NEM bontja a meglévő zárást.
-- ============================================================================

ALTER TABLE closing_wizard
    ADD COLUMN IF NOT EXISTS discrepancy_amount      NUMERIC(15,2),
    ADD COLUMN IF NOT EXISTS discrepancy_explanation VARCHAR(1000);
