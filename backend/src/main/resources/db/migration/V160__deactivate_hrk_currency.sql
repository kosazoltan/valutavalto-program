-- V160 (2026-04-23) - HRK (Horvat kuna) valuta deaktivalasa.
--
-- Hatter:
-- Horvatorszag 2023. januar 1-jen csatlakozott az euroovezethez; a HRK
-- 2023. januar 14. ota nem torvenyes fizetoeszkoz. Az EBC Zrt. penzvalto
-- rendszereben 2025. januar 1-je ota nem tortenik HRK tranzakcio.
--
-- A frontend menu + route (PR #145) mar eltavolitva. Ez a migration a
-- backend-oldali currencies tablaban allitja is_active=false -ra a HRK-t,
-- igy az aktiv valuta listakbol is eltunik (Rate management dropdown,
-- stock snapshot company totals stb.).
--
-- Reversibilis: ha valaha vissza kellene allitani, egy kezi
-- UPDATE currency SET is_active = true WHERE code = 'HRK' elegendo.

UPDATE currency
SET is_active = false
WHERE code = 'HRK'
  AND is_active = true;

-- Sanity check: ha HRK nincs a tablaban, ez no-op. Log-oljuk a sor-szamot.
DO $$
DECLARE
    affected_rows INT;
BEGIN
    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    RAISE NOTICE 'V160: HRK deactivation affected % row(s)', affected_rows;
END $$;