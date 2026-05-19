-- V236: nationality oszlop szelesitese VARCHAR(3) -> VARCHAR(100)
--
-- HIBA #13 (2026-05-19 user-reprodukciot megerositette): "Belso szerverhiba"
-- HTTP 500 az ugyfel rogzitesnel. Root cause: a Customer entity es a V3-ban
-- letrehozott customer + transaction tablakon a nationality oszlop VARCHAR(3)
-- (ISO 3166-1 alpha-3 kod) de a frontend "Magyar" / "EU-allampolgarsag" /
-- "Egyeb" (5-17 karakter) szoveget kuld. Postgres "value too long for type
-- character varying(3)" hibat dob -> 500.
--
-- A V229-ben hozza adott customer_nationality oszlopot a Transaction.java-n
-- nem ervintette ez, mert ott VARCHAR nincs explicit hossz (default 255), de
-- a V3-ban a customer + transaction.customer_nationality VARCHAR(3) volt.
--
-- A FIX: a kollegak humanreadable szoveget hasznalnak, ezert a VARCHAR(100)
-- ad eleg helyet ("Egyesult Allamok-i allampolgar" stb.).

ALTER TABLE customer
    ALTER COLUMN nationality TYPE VARCHAR(100);

-- V3-ban letrehozott transaction.customer_nationality is VARCHAR(3) volt
ALTER TABLE transaction
    ALTER COLUMN customer_nationality TYPE VARCHAR(100);

COMMENT ON COLUMN customer.nationality IS
    'V236 (2026-05-19): VARCHAR(100) - humanreadable allampolgarsag szoveg, NEM csak ISO3 kod. HIBA #13 fix.';
COMMENT ON COLUMN transaction.customer_nationality IS
    'V236 (2026-05-19): VARCHAR(100) - humanreadable allampolgarsag snapshot a bizonylathoz.';
