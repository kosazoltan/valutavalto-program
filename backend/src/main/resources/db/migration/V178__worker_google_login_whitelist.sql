-- V178: Google OAuth dolgozoi belepes whitelist mezok + indexek.
--
-- Audit forras: docs/AI_AGENT_FULL_REPAIR_INSTRUCTIONS_2026-05-03.md (Google OAuth audit doc)
-- Cel: a meglevo `worker.email` mellett explicit Google login whitelist + sub-binding,
-- valamint a fiok-azonositashoz a Google `sub` claim tarolasa.
--
-- A jelenlegi `GoogleAuthController.findByEmail(email)` minta hianyossagai:
--   - global lookup, NEM company-scoped,
--   - NEM case-insensitive garantalt,
--   - NEM ellenorzi explicit whitelist flag-et,
--   - nincs `google_sub` stabil azonositoja, igy ha az ugyfel Google fiokot valt
--     ugyanazon emaillel, NEM detektalhato.
--
-- Megoldas: kulonallo whitelist flag + indexed unique google_subject + canonical email
-- index.

ALTER TABLE worker
    ADD COLUMN IF NOT EXISTS google_subject VARCHAR(255),
    ADD COLUMN IF NOT EXISTS google_login_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS google_linked_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS google_last_login_at TIMESTAMP;

-- Subject egyediseg (cross-tenant is): egy Google fiok max EGY worker-hez kotheto.
-- Partial unique a NULL-okra: a meg NEM kotott workereken ez nem szamol.
CREATE UNIQUE INDEX IF NOT EXISTS uq_worker_google_subject
    ON worker (google_subject)
    WHERE google_subject IS NOT NULL;

-- Case-insensitive email lookup gyorsitas a whitelist-en-belul.
-- A query: WHERE google_login_enabled = true AND LOWER(email) = LOWER(:email)
CREATE INDEX IF NOT EXISTS idx_worker_google_email_lower
    ON worker (LOWER(email))
    WHERE google_login_enabled = TRUE;

-- Multi-tenant + email egyediseg whitelisten: ket worker NE tudjon ugyanazzal a Google
-- emaillel be lenni engedelyezve ugyanazon ceg-en belul (config error megelozese).
-- Cross-company NEM utkozik (pl. EBC + EXZ ket dolgozoja ugyanazt az emailt hasznalja).
CREATE UNIQUE INDEX IF NOT EXISTS uq_worker_company_google_email_lower
    ON worker (company_id, LOWER(email))
    WHERE google_login_enabled = TRUE
      AND email IS NOT NULL;
