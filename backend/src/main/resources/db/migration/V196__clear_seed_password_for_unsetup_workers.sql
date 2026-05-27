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
--
-- FIX (2026-05-27, live-API teszt): friss telepitesen / disaster-recovery-n / lokal-dev
-- fresh DB-n a seed-workerok (password_changed_at IS NULL + seed password_hash) NULL-update-je
-- a worker.password_hash NOT NULL constraintbe utkozott → a backend NEM indult el
-- ("null value in column password_hash violates not-null constraint"). A constraintet
-- eredetileg csak a KESOBBI V197 ejtette (DROP NOT NULL), igy a sorrend miatt a V196
-- fresh-apply-kor hamarabb futott es bukott. Productionon ez nem manifesztalodott, mert
-- ott a WHERE 0 sort erintett (a dolgozok mar password_changed_at-tel rendelkeztek).
-- Megoldas: a NOT NULL constraintet MAR ITT, az UPDATE ELOTT ejtjuk (idempotens — ha mar
-- nullable, no-op). A V197 ezutan redundans no-op. Establised production DB-n a V196 mar
-- alkalmazott → a checksum-valtozas miatt a kovetkezo deploy egyszeri FLYWAY_REPAIR_ON_MIGRATE=true
-- override-ot igenyel (a deploy-hetzner.yml repair-lepese / az override kezeli; 0-soros hatas).
ALTER TABLE worker ALTER COLUMN password_hash DROP NOT NULL;

UPDATE worker
SET password_hash = NULL
WHERE password_changed_at IS NULL
  AND password_hash IS NOT NULL;
