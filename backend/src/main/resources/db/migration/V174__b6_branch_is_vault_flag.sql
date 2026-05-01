-- v2.5.1-A B6: Branch.is_vault flag (atomic re-do, fixed table name)
--
-- Cél: a SetupWizard branch-választása CSAK az értéktári fiókokra szűkítse a listát
-- + a territoriális szűrés alapja (v2.5.1-D).
--
-- A 2026-05-01-i v2.5.0 outage POSTMORTEM: az előző V174 ALTER TABLE 'branches'
-- (PLURAL) volt — a backend Branch.java entity @Table(name="branch") (SINGULAR)-ra
-- mutat. A táblanév-eltérés miatt a deploy közben Flyway PSQLException-nel
-- elhasalt → 502-es production outage. Ez az atomic re-do helyes táblanévvel.
--
-- Idempotencia: IF NOT EXISTS guard, hogy ha a flyway_schema_history-ban marad
-- valami stale state, a migráció akkor is biztonságosan újrafutható.

ALTER TABLE branch
    ADD COLUMN IF NOT EXISTS is_vault BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_branch_is_vault ON branch (is_vault) WHERE is_vault = TRUE;

COMMENT ON COLUMN branch.is_vault IS
    'v2.5.1: TRUE=ÉRTÉKTÁR fiók (lokál vagy központi), FALSE=PÉNZTÁR (default). '
    'A SetupWizard értéktár módú telepítésnél csak is_vault=TRUE fiókokat enged. '
    'A territoriális szűrés alapja (vault_territory_id együttesében).';
