-- V254: A 8 értéktár (vault) `region` mezőjének beállítása (FK-004, Kasza Helga, 2026-05-21).
--
-- DIAGNÓZIS: a V239 a 8 vault-ot beszúrta `region_code`-dal (10/20/40/...), de a 40-karakteres
-- `region` mezőt (amit az Országos készlet nézet a területi csoportosításhoz használ) NEM
-- állította be → mind a 8 vault `region`-je ÜRES → a CashierStocksPage "BESOROLATLAN"
-- szekcióba sorolta őket. Az aktív pénztárak `region`-je a KESZLEX-konvenció szerinti
-- nagybetűs, ékezet nélküli kód (BEKESCSABA, DEBRECEN, KAPOSVAR, KECSKEMET, NYIREGYHAZA,
-- PECS, SZEGED, SZEKSZARD). A vaultokat ezekhez igazítjuk, így minden vault a saját
-- területi szekciójába kerül (FK-004: Szeged Értéktár → SZEGED), és az FK-003 vault-kártya
-- a szekció elejére tehető.
--
-- Idempotens: IS DISTINCT FROM guard.

UPDATE branch SET region = CASE code
        WHEN 'BR010' THEN 'SZEKSZARD'
        WHEN 'BR020' THEN 'SZEGED'
        WHEN 'BR040' THEN 'KECSKEMET'
        WHEN 'BR050' THEN 'DEBRECEN'
        WHEN 'BR063' THEN 'NYIREGYHAZA'
        WHEN 'BR075' THEN 'BEKESCSABA'
        WHEN 'BR120' THEN 'PECS'
        WHEN 'BR145' THEN 'KAPOSVAR'
        ELSE region
    END,
    updated_at = NOW()
 WHERE company_id = (SELECT id FROM company WHERE code = 'EBC')
   AND code IN ('BR010','BR020','BR040','BR050','BR063','BR075','BR120','BR145')
   AND region IS DISTINCT FROM (CASE code
        WHEN 'BR010' THEN 'SZEKSZARD'
        WHEN 'BR020' THEN 'SZEGED'
        WHEN 'BR040' THEN 'KECSKEMET'
        WHEN 'BR050' THEN 'DEBRECEN'
        WHEN 'BR063' THEN 'NYIREGYHAZA'
        WHEN 'BR075' THEN 'BEKESCSABA'
        WHEN 'BR120' THEN 'PECS'
        WHEN 'BR145' THEN 'KAPOSVAR'
        ELSE region
    END);
