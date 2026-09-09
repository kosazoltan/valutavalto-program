# Data-repair scripts

One-off, human-approved DML scripts run directly against the production database.
These are **archives**, not Flyway migrations: they are never executed automatically and
never appear in `flyway_schema_history`.

Rules for anything added here:

- Wrap the whole operation in a single transaction with `\set ON_ERROR_STOP on`.
- Scope every predicate as tightly as the schema allows and say so in the header: add
  `company_id` wherever the table has it (invariant #1), and where it does not
  (`denomination_balance`, `closing_wizard`, `closing_wizard_step`), scope by an explicit
  branch UUID list or transitively through the parent row — never by date alone.
- Take a full row-level export (`\copy ... CSV HEADER`) of every affected table **before**
  the write, and name that backup location in the script header.
- Emit a dedicated `audit_log` entry per affected branch with per-table row counts, and
  guard that INSERT so a rerun which changes nothing writes no audit row. `audit_log` is
  append-only (`audit_log_no_update` / `audit_log_no_delete` triggers), so a wrong entry
  can never be corrected in place — only annotated by a further append.
- Direct-SQL `audit_log` inserts do **not** get the H11 tamper-evidence chain that
  `AuditLogService.applyHashChain` adds. Either compute `entry_hash` / `previous_hash` in
  the script with the same formula, or append a chain-annex row naming the unhashed ids.
- Report the deleted/updated counts from `RETURNING`, never from a `RAISE NOTICE`.

| script | ticket | scope |
|---|---|---|
| `2026-09-09-fkh058-tisza-sarok-test-data-purge.sql` | FKH-058, executed under FKH-059 FR-2 | Pre-2026-09-01 test data purge for BR035 Szeged Tisza Sarok, BR027 Szeged Tesco and the inactive TISZA duplicate |
| `2026-09-09-fkh059-audit-chain-annex.sql` | FKH-059 review follow-up | Appends the H11 chain-annex row covering the three direct-SQL purge audit entries |
