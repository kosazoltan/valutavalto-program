-- V211: Penztarosi sav (cashier custom rate) nyomkovetes
-- Zsuzsa/belso ellenor keres: 400k+ Ft felett napi 5x egyedi arfolyam

ALTER TABLE transaction ADD COLUMN IF NOT EXISTS cashier_custom_rate BOOLEAN DEFAULT FALSE;

-- Rendszerparameter: penztarosi egyedi arfolyam minimum osszeg (Ft)
INSERT INTO system_parameter (key, value, category, description)
VALUES ('CASHIER_CUSTOM_RATE_MIN_AMOUNT', '400000', 'TRANSACTION', 'Penztarosi egyedi arfolyam minimum HUF osszeg')
ON CONFLICT (key) DO NOTHING;

-- Rendszerparameter: penztarosi egyedi arfolyam napi limit
INSERT INTO system_parameter (key, value, category, description)
VALUES ('CASHIER_CUSTOM_RATE_DAILY_LIMIT', '5', 'TRANSACTION', 'Penztarosi egyedi arfolyam napi limit (db/penztaros)')
ON CONFLICT (key) DO NOTHING;
