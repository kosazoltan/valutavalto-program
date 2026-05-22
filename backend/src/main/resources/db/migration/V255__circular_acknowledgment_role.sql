-- G21: körlevél szerepkörönkénti visszaigazolás-bontás (EXCMD b9-korlevelek FR-2).
-- A circular_acknowledgment eddig csak worker_id-t tárolt; a szerepkör (Pénztáros /
-- Belső ellenőr / Területi vezető stb.) szerinti visszaigazolás-megoszlás nem volt követhető.
-- Additív, idempotens oszlop — meglévő sorok NULL-lal maradnak (ismeretlen szerepkör).
ALTER TABLE circular_acknowledgment
    ADD COLUMN IF NOT EXISTS acknowledger_role VARCHAR(50);
