-- V198: MINDEN dolgozo jelszavanak es password_changed_at-jenek torlese.
--
-- Root cause (2026-05-11 production debug):
--   A V196 csak a password_changed_at IS NULL sorokat clearelte.
--   De V193 a KOSA workerre, es a korabbi SetupWizard-on keresztuli sikeres
--   first-time-setup a tobbi dolgozora (BORSI, BALI, KASZA) mar kitoltotte
--   a password_changed_at mezoket. Igy a V196 SENKIT nem erintett a 4 fo
--   dolgozobol.
--
--   A WorkerFirstTimeSetupService logikaja:
--     1. passwordChangedAt != null -> currentPassword KOTELEZO (102. sor)
--     2. passwordHash != null      -> seed password KOTELEZO (109. sor)
--     3. passwordHash == null + bootstrapCompleted -> BLOKKOLVA (119. sor)
--     4. passwordHash == null + !bootstrapCompleted -> SZABAD (125. sor)
--
--   Production: bootstrapCompleted = true, igy a 3. ag blokkolja azokat
--   akiknek passwordHash == null + passwordChangedAt == null.
--   A 4. ag soha nem igaz production-on.
--
--   Kovetkezmeny: EGYETLEN dolgozo sem tud jelszot beallitani a SetupWizard-on
--   keresztul ujratelepiteskor. Ez a hiba 1 hete blokkol.
--
-- Megoldas (ket lepes, atomi):
--   1. Ez a migracio: password_hash = NULL, password_changed_at = NULL
--      MINDEN dolgozonal — igy a backend a "fresh first-time-setup" agba kerul.
--   2. A WorkerFirstTimeSetupService 119-123 sor modositasa: ha passwordHash == null
--      es passwordChangedAt == null, bootstrap lezart utan is engedjen uj jelszot.
--      (Ez a V198 + Java fix EGYUTT oldja meg a problemat.)

UPDATE worker
SET password_hash = NULL,
    password_changed_at = NULL;
