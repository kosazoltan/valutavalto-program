-- V127: Meghatalmazott entity bővítés a v2.0 felmérés alapján
-- Új mezők: személyes adatok, okmány részletek, típus/kapcsolat szótárak

ALTER TABLE authorized_representative ADD COLUMN IF NOT EXISTS first_name VARCHAR(100);
ALTER TABLE authorized_representative ADD COLUMN IF NOT EXISTS last_name VARCHAR(100);
ALTER TABLE authorized_representative ADD COLUMN IF NOT EXISTS birth_date DATE;
ALTER TABLE authorized_representative ADD COLUMN IF NOT EXISTS birth_place VARCHAR(200);
ALTER TABLE authorized_representative ADD COLUMN IF NOT EXISTS nationality_did VARCHAR(50);
ALTER TABLE authorized_representative ADD COLUMN IF NOT EXISTS address VARCHAR(500);
ALTER TABLE authorized_representative ADD COLUMN IF NOT EXISTS phone VARCHAR(50);
ALTER TABLE authorized_representative ADD COLUMN IF NOT EXISTS email VARCHAR(200);
ALTER TABLE authorized_representative ADD COLUMN IF NOT EXISTS document_type_did VARCHAR(50);
ALTER TABLE authorized_representative ADD COLUMN IF NOT EXISTS document_valid_from DATE;
ALTER TABLE authorized_representative ADD COLUMN IF NOT EXISTS document_valid_to DATE;
ALTER TABLE authorized_representative ADD COLUMN IF NOT EXISTS representative_type_did VARCHAR(50);
ALTER TABLE authorized_representative ADD COLUMN IF NOT EXISTS relationship_did VARCHAR(50);

-- Index az okmányszámra (keresés gyorsítás)
CREATE INDEX IF NOT EXISTS idx_auth_rep_document ON authorized_representative(representative_document_number);
