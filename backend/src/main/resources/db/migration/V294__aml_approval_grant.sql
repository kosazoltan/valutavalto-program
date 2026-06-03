-- AML felsovezetoi jovahagyas — engedely ("grant") a PIN-jelenlet bizonyitasara.
--
-- Codex P1 (2026-06-04): a /aml-approval/verify-approver eddig csak az approverWorkerId-t adta vissza,
-- es a tranzakcio-rogzites (recordSeniorApproval) ezt PIN-bizonyitek nelkul elfogadta. Egy authentikalt
-- penztaros igy a modal/PIN megkerulesevel barmely supervisor id-jat beadhatta volna -> hamis jovahagyas-
-- audit a supervisor jelenlete nelkul.
--
-- Megoldas: a PIN sikeres ellenorzesekor a szerver letrehoz EGY grant-rekordot, fix uses_remaining
-- kapuval (= a multi-line nyugta max sorszama). A tranzakcio-rogzites CSAK akkor rogzit jovahagyast, ha
-- van fel nem hasznalt (uses_remaining>0), le nem jart grant a (company, penztaros, engedelyezo) harmasra;
-- rogziteskor a grant uses_remaining-je ATOMIKUS feltteles UPDATE-tel csokken (race-mentes single-use).
-- A count NEM a klienstol jon (Codex P1 #2: "derive instead of trusting the request"). A 7 napos lejarat
-- a local-first offline -> sync kesleltetest fedi (operacios biztonsag: rogzitett+jovahagyott tranzakcio
-- ne bukjon sync-kor).

CREATE TABLE IF NOT EXISTS aml_approval_grant (
    id                  BIGSERIAL PRIMARY KEY,
    company_id          UUID      NOT NULL,
    cashier_worker_id   BIGINT    NOT NULL,
    approver_worker_id  BIGINT    NOT NULL,
    -- A jovahagyas-session (nyugta/keres) azonosito, amit a kliens a modal megnyitasakor general, es
    -- amit a nyugta MINDEN tranzakcioja magaval visz. A grant CSAK az ezzel a session_id-vel tagelt
    -- tranzakciokat hagyhatja jova -> a maradek felhasznalasok NEM szivaroghatnak masik nyugtara
    -- (Codex P1: receipt-scoping).
    session_id          VARCHAR(64) NOT NULL,
    created_at          TIMESTAMP NOT NULL DEFAULT now(),
    expires_at          TIMESTAMP NOT NULL,
    -- Hatralevo felhasznalasok szama (server-fix kapu egy PIN-ellenorzesbol; 0 = kimerult).
    uses_remaining      INTEGER   NOT NULL DEFAULT 1
);

-- A consume-lookup gyorsitasa: (company, penztaros, engedelyezo, session) + meg felhasznalhato grantok.
CREATE INDEX IF NOT EXISTS ix_aml_approval_grant_consume
    ON aml_approval_grant (company_id, cashier_worker_id, approver_worker_id, session_id, uses_remaining);
