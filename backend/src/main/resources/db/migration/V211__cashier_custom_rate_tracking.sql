-- V211: Penztarosi sav (cashier custom rate) nyomkovetes
-- Zsuzsa/belso ellenor keres: 400k+ Ft felett napi 5x egyedi arfolyam
--
-- HOTFIX 2026-05-13 (fresh-deploy fix, PR #574):
-- Az eredeti V211 'key'/'value' INSERT oszlopneveket hasznalt, ami nem letezo oszlop
-- a system_parameter taban (helyette: parameter_key/parameter_value, V135 utan).
-- Production-on V211 manualisan flyway-repair-elve van (success=t, checksum=1782720344)
-- + V213__fix_V211_cashier_custom_rate_params.sql INSERT-elte az adatot.
-- Fresh deploy eseten az eredeti hibas SQL crash-elt volna. Ez a javitas helyes
-- oszlopneveket hasznal + ON CONFLICT DO NOTHING (idempotens — V213 utan re-run safe).
--
-- Production deploy KOVETKEZO alkalmaval KOTELEZO env var: FLYWAY_REPAIR_ON_MIGRATE=true
-- (egy deploy, hogy az uj checksum frissuljon a flyway_schema_history-ban). Lasd:
-- vault/operations/v211-fresh-deploy-fix.md

ALTER TABLE transaction ADD COLUMN IF NOT EXISTS cashier_custom_rate BOOLEAN DEFAULT FALSE;

-- Rendszerparameter: penztarosi egyedi arfolyam minimum osszeg (Ft)
INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active, updated_at, updated_by)
VALUES (gen_random_uuid(), 'CASHIER_CUSTOM_RATE_MIN_AMOUNT', '400000', 'STRING', 'TRANSACTION', 'Penztarosi egyedi arfolyam minimum HUF osszeg', true, now(), 'SYSTEM')
ON CONFLICT (parameter_key) DO NOTHING;

-- Rendszerparameter: penztarosi egyedi arfolyam napi limit
INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active, updated_at, updated_by)
VALUES (gen_random_uuid(), 'CASHIER_CUSTOM_RATE_DAILY_LIMIT', '5', 'STRING', 'TRANSACTION', 'Penztarosi egyedi arfolyam napi limit (db/penztaros)', true, now(), 'SYSTEM')
ON CONFLICT (parameter_key) DO NOTHING;
