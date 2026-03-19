-- V100: Transfer direction mező (legacy U/F/UF/FF counter-transaction logika)
ALTER TABLE transfer ADD COLUMN direction VARCHAR(2) DEFAULT 'UF';

-- Meglévő transzfereknél UF (teljes körforgás) a default
UPDATE transfer SET direction = 'UF' WHERE direction IS NULL;

COMMENT ON COLUMN transfer.direction IS 'Átadás iránya: F=Feladó, U=Vevő, UF=Mindkettő, FF=Korrekció';
