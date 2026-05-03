-- Audit P0.3 (2026-05-03): refresh token selector/verifier pattern.
--
-- A korabbi `AuthController.refreshCookie` minden refresh-kor `findAll()`
-- lekerdezett es BCrypt.matches() futtatott MINDEN aktiv tokenre.
-- O(N) BCrypt = ~150ms/token = 100 token mellett ~15s + DoS-kockazat.
--
-- Megoldas: selector/verifier pattern (Laravel/Symfony minta):
--   - cookie: `<selector>.<verifier>` (pl. `4SR4qF...XnA9.eGhJ87...zKp4`)
--   - DB-ben: `selector` indexed UNIQUE + `token_hash` (verifier BCrypt-hashe)
--   - lookup: O(1) DB index a selector-re, majd EGYETLEN BCrypt verifyt
--
-- Migracio: a `selector` oszlop NULL-ABLE-kent kerul be. A meglevo tokenek
-- (selector IS NULL) nem matchelhetok az uj refresh-cookie endpointon, igy
-- a felhasznaloknak ujra kell loginolni — de a regi tokenek 7 napon belul
-- expire-olnak amugy, igy ez nem destruktiv. Logout-flow (findActiveForWorker)
-- workerId-vel scope-ol, ezert backward compat tovabbra is mukodik.

ALTER TABLE refresh_token ADD COLUMN IF NOT EXISTS selector VARCHAR(64);

-- Partial unique index — csak nem-NULL selector ertekekre.
-- Igy a meglevo tokenek (selector IS NULL) nem osszeutkoznek.
CREATE UNIQUE INDEX IF NOT EXISTS refresh_token_selector_idx
    ON refresh_token (selector)
    WHERE selector IS NOT NULL;
