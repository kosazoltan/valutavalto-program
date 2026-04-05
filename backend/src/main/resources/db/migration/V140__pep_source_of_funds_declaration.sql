-- V140: PEP és Jogcím nyilatkozat mezők (G3-G4 Legacy Gap Fix)
-- Legacy: BLOKNYOM/KozszerepNyilatkozat + Jogcimnyilatkozat
-- 300.000 Ft feletti tranzakciónál törvényi kötelezettség

ALTER TABLE transaction ADD COLUMN IF NOT EXISTS source_of_funds VARCHAR(500);
ALTER TABLE transaction ADD COLUMN IF NOT EXISTS customer_is_pep BOOLEAN DEFAULT FALSE;

COMMENT ON COLUMN transaction.source_of_funds IS 'Pénzeszköz forrása — 300k+ Ft tranzakciónál kötelező (Legacy: _forras)';
COMMENT ON COLUMN transaction.customer_is_pep IS 'Ügyfél PEP státusza a tranzakció pillanatában (Legacy: _kozszereplo)';
