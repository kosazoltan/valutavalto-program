-- V143: Customer érzékeny mezők titkosítás előkészítés
-- Az EncryptedStringConverter AES output hosszabb mint az eredeti — column size növelés kötelező.
-- A tényleges titkosítás a JPA @Convert annotáción keresztül automatikusan történik
-- minden INSERT/UPDATE műveletnél. A meglévő plaintext adatok a következő UPDATE-nél titkosítódnak.

-- GDPR Art. 87 — személyi okmány adatok
ALTER TABLE customer ALTER COLUMN document_number TYPE VARCHAR(200);
ALTER TABLE customer ALTER COLUMN id_card_number TYPE VARCHAR(200);
ALTER TABLE customer ALTER COLUMN passport_number TYPE VARCHAR(200);

-- GDPR Art. 9 — azonosító adatok
ALTER TABLE customer ALTER COLUMN mother_name TYPE VARCHAR(600);
ALTER TABLE customer ALTER COLUMN birth_place TYPE VARCHAR(300);

-- GDPR Art. 6 — kapcsolattartási adatok
ALTER TABLE customer ALTER COLUMN address TYPE VARCHAR(1500);
ALTER TABLE customer ALTER COLUMN phone TYPE VARCHAR(200);
ALTER TABLE customer ALTER COLUMN email TYPE VARCHAR(300);

-- Adóügyi titoktartás
ALTER TABLE customer ALTER COLUMN tax_number TYPE VARCHAR(200);

-- Index eltávolítás: titkosított mező nem indexelhető hagyományosan
DROP INDEX IF EXISTS idx_customer_document;
