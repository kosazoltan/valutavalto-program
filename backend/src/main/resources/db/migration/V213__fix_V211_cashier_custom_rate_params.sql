-- V213: V211 javitas — a V211 hibas oszlopneveket (key/value) hasznalt
-- az INSERT-ekben, igy a system_parameter sorok nem kerultek be.
-- Ez a migracio a helyes oszlopnevekkel (parameter_key/parameter_value)
-- beszurja oket. ON CONFLICT DO NOTHING: ha mar leteznek (pl. kezzel fixelve),
-- nem duplikal.

INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active, updated_at, updated_by)
VALUES (gen_random_uuid(), 'CASHIER_CUSTOM_RATE_MIN_AMOUNT', '400000', 'STRING', 'TRANSACTION', 'Penztarosi egyedi arfolyam minimum HUF osszeg', true, now(), 'SYSTEM')
ON CONFLICT (parameter_key) DO NOTHING;

INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active, updated_at, updated_by)
VALUES (gen_random_uuid(), 'CASHIER_CUSTOM_RATE_DAILY_LIMIT', '5', 'STRING', 'TRANSACTION', 'Penztarosi egyedi arfolyam napi limit (db/penztaros)', true, now(), 'SYSTEM')
ON CONFLICT (parameter_key) DO NOTHING;
