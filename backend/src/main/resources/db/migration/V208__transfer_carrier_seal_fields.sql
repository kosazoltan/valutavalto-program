-- V200: Szallito nev es plombaszam mezo hozzaadasa az atadas tablához
ALTER TABLE transfer ADD COLUMN IF NOT EXISTS carrier_name VARCHAR(200);
ALTER TABLE transfer ADD COLUMN IF NOT EXISTS seal_number VARCHAR(100);
