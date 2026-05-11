-- V197: worker.password_hash NOT NULL constraint eltavolitasa.
--
-- Elozmeny: A V196 migracio SET password_hash = NULL-t probal seed-jelszo torleskent,
-- de a kolonna NOT NULL constraint-je miatt PSQL ERROR-t dobott production-ban:
--   "null value in column password_hash of relation worker violates not-null constraint"
--
-- Megoldas: DROP NOT NULL → a V196 ujrafutasa (repair utan) sikeresen NULL-ra allitja
-- a seed jelszavakat, es a WorkerFirstTimeSetupService jelentszo nelkul engedi
-- az uj jelszo beallitast (hasPasswordHash() == false -> skip password check).
--
-- Idempotens: ha mar nullable, a DROP NOT NULL nem csinál semmit.

ALTER TABLE worker ALTER COLUMN password_hash DROP NOT NULL;
