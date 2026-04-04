-- V100: P0 Sprint 1 — SHK limit 3→5 + Konverzió díj=0 dokumentáció
-- Gap: GAP-P0-003 (SHK napi limit eltérés Delphi 5 vs Java 3)
-- A Delphi rendszerben max 5 SHK/nap volt engedélyezve (HARDWARE.SAJATHATASKORU)
-- A Java rendszer SystemParameter-ből olvassa → frissítjük 5-re

UPDATE system_parameter
SET parameter_value = '5',
    description = 'Napi saját hatáskörű kedvezmény (SHK) limit. Legacy: HARDWARE.SAJATHATASKORU max 5/nap'
WHERE parameter_key = 'DAILY_CUSTOM_FEE_LIMIT';

-- Ha nem létezik (pl. friss install), beszúrjuk
INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
SELECT gen_random_uuid(), 'DAILY_CUSTOM_FEE_LIMIT', '5', 'INTEGER', 'HANDLING_FEE',
       'Napi saját hatáskörű kedvezmény (SHK) limit. Legacy: HARDWARE.SAJATHATASKORU max 5/nap',
       true
WHERE NOT EXISTS (SELECT 1 FROM system_parameter WHERE parameter_key = 'DAILY_CUSTOM_FEE_LIMIT');
