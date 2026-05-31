-- V279: F-001 átmeneti grace — a setup-token követelmény NE zárja ki a folyamatban lévő
-- (deploy-pillanatban már null-hash) dolgozókat a first-time setupból.
--
-- A V278 (F-001) fix a bootstrap-lezárt utáni null-hash first-time-worker-setuphoz admin
-- setup-tokent követel. A jelenlegi kollégák egy része (pl. BALI — V230/V231 reset) MOST
-- null-hash állapotban van, és a meglévő (token nélküli) flow-n állítaná be a jelszavát.
-- Hogy a deploy NE zárja ki őket, ezek a dolgozók EGYSZERI 'grace'-t kapnak: a guard
-- token nélkül is engedi a setupot, majd a sikeres beállításkor a grace lezárul.
-- Minden EZUTÁNI (új) null-hash reset már setup-tokent igényel (a fix érvényben marad).

ALTER TABLE worker ADD COLUMN IF NOT EXISTS setup_grace BOOLEAN NOT NULL DEFAULT FALSE;

-- A deploy pillanatában már teljesen resetelt (null-hash) dolgozók egyszeri grace-t kapnak.
UPDATE worker
   SET setup_grace = TRUE
 WHERE password_hash IS NULL
   AND password_changed_at IS NULL;
