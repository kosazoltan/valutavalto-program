-- V268: customer.country oszlop szelesitese VARCHAR(3) -> VARCHAR(100)
--
-- HIBA #5 (2026-05-27, elo-API kereszt­metszet-teszt): "Belso szerverhiba" HTTP 500
-- az ugyfel rogzitesnel (POST /api/v1/customers), ha a country mezo ki van toltve.
-- Root cause: a V3-ban letrehozott customer.country oszlop VARCHAR(3) (ISO 3166-1
-- alpha-3 orszagkodnak szant), DE a frontend (CustomerCreatePage) alapertelmezetten
-- a "Magyarorszag" humanreadable orszagnevet kuldi (12 karakter, szabad-szoveges input).
-- Postgres "value too long for type character varying(3)" -> 500.
--
-- Ez UGYANAZ a hiba-osztaly, mint a V236 (nationality VARCHAR(3) -> VARCHAR(100)),
-- de a V236 csak a nationality-t szelesitette, a country-t nem.
--
-- A FIX: a kollegak humanreadable orszagnevet hasznalnak, ezert a VARCHAR(100)
-- ad eleg helyet ("Magyarorszag", "Egyesult Allamok", stb.). Adatvesztes nincs
-- (szelesites, a meglevo <=3 karakteres ertekek valtozatlanok).

ALTER TABLE customer
    ALTER COLUMN country TYPE VARCHAR(100);

COMMENT ON COLUMN customer.country IS
    'V268 (2026-05-27): VARCHAR(100) - humanreadable orszagnev szoveg, NEM csak ISO3 kod. HIBA #5 fix (elo-API teszt).';
