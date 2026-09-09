# Data-repair scripts

One-off, human-approved DML scripts run directly against the production database.
These are **archives**, not Flyway migrations: they are never executed automatically and
never appear in `flyway_schema_history`.

Rules for anything added here:

- Wrap the whole operation in a single transaction with `\set ON_ERROR_STOP on`.
- Company-scope every predicate (invariant #1) and state the branch UUIDs explicitly.
- Take a full row-level export (`\copy ... CSV HEADER`) of every affected table **before**
  the write, and name that backup location in the script header.
- Emit a dedicated `audit_log` entry per affected branch with per-table row counts.
- Report the deleted/updated counts from `RETURNING`, never from a `RAISE NOTICE`.

| script | ticket | scope |
|---|---|---|
| `2026-09-09-fkh058-tisza-sarok-test-data-purge.sql` | FKH-058, executed under FKH-059 FR-2 | Pre-2026-09-01 test data purge for BR035 Szeged Tisza Sarok, BR027 Szeged Tesco and the inactive TISZA duplicate |
