-- V214: foreign_status oszlop DB-szintu CHECK constraint (Copilot finding from PR #562)
-- A V210 migracio óta a `transaction.foreign_status` szabad szövegként került mentésre.
-- Mostantól a DB megakadályozza az érvénytelen értékeket: csak DOMESTIC, FOREIGN, vagy NULL.

-- 1. Korábbi rossz adatok normalizálása — CSAK a tényleg módosítandó sorok (table-rewrite elkerülése)
-- Copilot finding: a "WHERE foreign_status IS NOT NULL" túl bő scope, minden sort felülírná
UPDATE transaction
SET foreign_status = UPPER(TRIM(foreign_status))
WHERE foreign_status IS NOT NULL
  AND foreign_status <> UPPER(TRIM(foreign_status));

-- 2. Csak DOMESTIC vagy FOREIGN engedélyezett, NULL továbbra is OK (régi adatokra)
-- Az UPPER(TRIM(...)) után csak a tényleg érvénytelenek maradnak
UPDATE transaction
SET foreign_status = NULL
WHERE foreign_status IS NOT NULL
  AND foreign_status NOT IN ('DOMESTIC', 'FOREIGN');

-- 3. CHECK constraint a jövőre
ALTER TABLE transaction
DROP CONSTRAINT IF EXISTS chk_transaction_foreign_status;

ALTER TABLE transaction
ADD CONSTRAINT chk_transaction_foreign_status
CHECK (foreign_status IS NULL OR foreign_status IN ('DOMESTIC', 'FOREIGN'));
