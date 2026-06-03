-- AML felsovezetoi jovahagyas — egyszer-hasznalatos engedely ("grant").
--
-- Codex P1 (2026-06-04): a /aml-approval/verify-approver eddig csak az approverWorkerId-t adta vissza,
-- es a tranzakcio-rogzites (recordSeniorApproval) ezt PIN-bizonyitek nelkul elfogadta. Egy authentikalt
-- penztaros igy a modal/PIN megkerulesevel barmely supervisor id-jat beadhatta volna -> hamis jovahagyas-
-- audit a supervisor jelenlete nelkul.
--
-- Megoldas: a PIN sikeres ellenorzesekor a szerver letrehoz egy egyszer-hasznalatos grant-rekordot
-- (company + penztaros + engedelyezo + lejarat). A tranzakcio-rogzites CSAK akkor rogzit jovahagyast,
-- ha van fel nem hasznalt, le nem jart grant a (company, penztaros, engedelyezo) harmasra; rogziteskor
-- a grant elhasznalodik (used_at). A 7 napos lejarat a local-first offline -> sync kesleltetest fedi.

CREATE TABLE IF NOT EXISTS aml_approval_grant (
    id                  BIGSERIAL PRIMARY KEY,
    company_id          UUID      NOT NULL,
    cashier_worker_id   BIGINT    NOT NULL,
    approver_worker_id  BIGINT    NOT NULL,
    created_at          TIMESTAMP NOT NULL DEFAULT now(),
    expires_at          TIMESTAMP NOT NULL,
    used_at             TIMESTAMP
);

-- A consume-lookup gyorsitasa: (company, penztaros, engedelyezo) + meg fel nem hasznalt grantok.
CREATE INDEX IF NOT EXISTS ix_aml_approval_grant_consume
    ON aml_approval_grant (company_id, cashier_worker_id, approver_worker_id, used_at);
