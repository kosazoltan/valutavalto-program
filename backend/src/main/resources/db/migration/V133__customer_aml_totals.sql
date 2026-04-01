-- V133: Ügyfél AML göngyölítő mezők
-- Legacy: HETIOSSZ, FORINTOSSZEG/HASFORINT, EVIMAX

ALTER TABLE customer ADD COLUMN IF NOT EXISTS weekly_total NUMERIC(18,2) DEFAULT 0;
ALTER TABLE customer ADD COLUMN IF NOT EXISTS annual_total NUMERIC(18,2) DEFAULT 0;
ALTER TABLE customer ADD COLUMN IF NOT EXISTS annual_max NUMERIC(18,2) DEFAULT 0;

COMMENT ON COLUMN customer.weekly_total IS 'Heti forgalom göngyölítés (HUF)';
COMMENT ON COLUMN customer.annual_total IS 'Éves forgalom göngyölítés (HUF)';
COMMENT ON COLUMN customer.annual_max IS 'Éves maximum egyedi tranzakció (HUF)';
