-- V55: Külön személyi ig. szám és útlevél szám mezők
-- Backward compatible: régi documentNumber/documentType megmarad!

ALTER TABLE customer ADD COLUMN IF NOT EXISTS id_card_number VARCHAR(30);
ALTER TABLE customer ADD COLUMN IF NOT EXISTS id_card_expiry DATE;
ALTER TABLE customer ADD COLUMN IF NOT EXISTS passport_number VARCHAR(30);
ALTER TABLE customer ADD COLUMN IF NOT EXISTS passport_expiry DATE;

-- Indexek kereséshez
CREATE INDEX IF NOT EXISTS idx_customer_id_card ON customer(id_card_number);
CREATE INDEX IF NOT EXISTS idx_customer_passport ON customer(passport_number);
CREATE INDEX IF NOT EXISTS idx_customer_phone ON customer(phone);
CREATE INDEX IF NOT EXISTS idx_customer_email ON customer(email);

-- Meglévő documentNumber adatok migrálása az új mezőkbe
UPDATE customer SET id_card_number = document_number WHERE document_type = 'ID_CARD' AND document_number IS NOT NULL;
UPDATE customer SET passport_number = document_number WHERE document_type = 'PASSPORT' AND document_number IS NOT NULL;
