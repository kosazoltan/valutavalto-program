-- V193: KOSA worker jelszo reset (2026-05-08)
-- Az Setup Wizard beallitotta a jelszot, de a user nem tudja bevinni a login oldalon.
-- Uj jelszo: support-reset (BCrypt $2b$10$ hash, plaintext out-of-band)
UPDATE worker
SET password_hash = '$2b$10$JVsZupVf47P5vwDFLglmxOvRc07Whmsn7p7blYPcdHavi4oyYC6Wi',
    password_changed_at = NOW()
WHERE code = 'KOSA'
  AND company_id = (SELECT id FROM company WHERE code = 'EBC');
