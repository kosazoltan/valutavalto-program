-- V230: BALI password_hash NULL — SetupWizard 'first install' treatment
--
-- User-jelentes 2026-05-15 (Kosa Zoltan utan a v2.5.53 telepito SetupWizard):
-- "A dolgozói jelszó beállítása nem sikerült: A jelenlegi jelszó nem egyezik.
--  Add meg a jelenlegi vagy kezdő dolgozói jelszót az admin jelszó lépésen."
--
-- ROOT CAUSE: V228 reaktivalta a BALI worker-t (is_active=TRUE), de a BCrypt
-- password_hash megmaradt a regi (V203 elotti) jelszobol. A user nem emlekszik
-- erre a regi jelszora, igy a SetupWizard step 5 "Jelenlegi jelszó" check
-- minden probalassal kudarcot vall.
--
-- A V196 migracio mar tamogatja a NULL password_hash-t (first-time-setup elott
-- a seed password torolheto). Ezzel a V230 hotfix-szel a BALI worker
-- password_hash-et NULL-ra allitjuk, igy a SetupWizard "elso telepitesnek"
-- erteklezi es elfogadja az uj jelszot.
--
-- AUDIT: Kosa Zoltan CEO direkt user-direktivaja alapjan, 2026-05-15-i
-- masodik mega-session, telepito v2.5.53 utan.

UPDATE worker
SET password_hash = NULL,
    password_changed_at = NULL
WHERE code = 'BALI'
  AND company_id = (SELECT id FROM company WHERE code = 'EBC')
  AND is_active = TRUE;

-- Log
DO $$
DECLARE
    affected_count INT;
BEGIN
    SELECT count(*) INTO affected_count
    FROM worker
    WHERE code = 'BALI'
      AND company_id = (SELECT id FROM company WHERE code = 'EBC')
      AND is_active = TRUE
      AND password_hash IS NULL;
    RAISE NOTICE 'V230: BALI worker password_hash NULL-azva, affected=%', affected_count;
END$$;
