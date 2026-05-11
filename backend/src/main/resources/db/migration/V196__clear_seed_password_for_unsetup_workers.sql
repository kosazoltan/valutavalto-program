-- V196: Seed jelszo torlese azoknál a dolgozonknal, akik soha nem allitottak be sajat jelszot.
--
-- Problem: A V145 migracio seed password hash-t (BCrypt("1234")) adott a dolgozoknak,
-- de a SetupWizard ujratelepites utan megkoveteli ennek ismeretet. A felhasznalok
-- nem tudjak a seed jelszot, igy a "Telepites befejezese" hibat dob.
--
-- Megoldas: Ha password_changed_at IS NULL, a dolgozo soha nem allitott be sajat jelszot.
-- A seed hash torlese lehetove teszi, hogy a first-time-setup endpoint jelszo nelkul
-- engedje az uj jelszo beallitasat (WorkerFirstTimeSetupService 119-126. sor logika).
--
-- Biztonsag: Csak seed-allapotu fiokokat erint. Mar aktiv jelszoval rendelkezo
-- dolgozok (password_changed_at IS NOT NULL) NEM modosulnak.

UPDATE worker
SET password_hash = NULL
WHERE password_changed_at IS NULL
  AND password_hash IS NOT NULL;
