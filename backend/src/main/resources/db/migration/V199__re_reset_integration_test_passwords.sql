-- V199: Integration teszt altal beallitott jelszavak torlese.
--
-- A V198 fix tesztelese soran a KOSA, BORSI, BALI dolgozoknak
-- ideiglenesen beallitodott az "IntegrationTest_DO_NOT_USE" jelszo.
-- Ez a migracio ujra reseteli oket, hogy a SetupWizard ujratelepiteskor
-- szabadon allithassanak be valodi jelszot.

UPDATE worker
SET password_hash = NULL,
    password_changed_at = NULL
WHERE code IN ('KOSA', 'BORSI', 'BALI')
  AND company_id = (SELECT id FROM company WHERE code = 'EBC');
