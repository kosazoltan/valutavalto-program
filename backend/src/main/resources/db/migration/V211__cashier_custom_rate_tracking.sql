-- V211: Penztarosi sav (cashier custom rate) nyomkovetes
-- Zsuzsa/belso ellenor keres: 400k+ Ft felett napi 5x egyedi arfolyam

ALTER TABLE transaction ADD COLUMN IF NOT EXISTS cashier_custom_rate BOOLEAN DEFAULT FALSE;

-- Rendszerparameter: penztarosi egyedi arfolyam minimum osszeg (Ft)
INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active, updated_at, updated_by)
VALUES (gen_random_uuid(), 'CASHIER_CUSTOM_RATE_MIN_AMOUNT', '400000', 'STRING', 'TRANSACTION', 'Penztarosi egyedi arfolyam minimum HUF osszeg', true, now(), 'SYSTEM')
ON CONFLICT (parameter_key) DO NOTHING;

-- Rendszerparameter: penztarosi egyedi arfolyam napi limit
INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active, updated_at, updated_by)
VALUES (gen_random_uuid(), 'CASHIER_CUSTOM_RATE_DAILY_LIMIT', '5', 'STRING', 'TRANSACTION', 'Penztarosi egyedi arfolyam napi limit (db/penztaros)', true, now(), 'SYSTEM')
ON CONFLICT (parameter_key) DO NOTHING;
