-- FKH-058 (executed under FKH-059 FR-2): delete pre-2026-09-01 test data
-- Scope approved by the user (option A + closing_wizard/closing_control):
--   BR035 Szeged Tisza Sarok  2f16b7e9-6a09-422f-bb67-423f4a2bc32b
--   BR027 Szeged Tesco        41654a34-b0a7-443c-9088-05bc58693af5
--   TISZA Tisza Sarok (inactive duplicate) dd29ef03-c7cc-4fb8-9106-045991627a85
-- Tables: denomination_balance, daily_balance, daily_session, closing_wizard, closing_control
-- Company-scoped (invariant #1). Backup taken first: /root/fkh058-backup/*.csv
\set ON_ERROR_STOP on
BEGIN;

CREATE TEMP TABLE fkh058_branch(branch_id uuid PRIMARY KEY, code text, name text) ON COMMIT DROP;
INSERT INTO fkh058_branch VALUES
  ('2f16b7e9-6a09-422f-bb67-423f4a2bc32b', 'BR035', 'Szeged Tisza Sarok'),
  ('41654a34-b0a7-443c-9088-05bc58693af5', 'BR027', 'Szeged Tesco'),
  ('dd29ef03-c7cc-4fb8-9106-045991627a85', 'TISZA', 'Tisza Sarok');

CREATE TEMP TABLE fkh058_counts(branch_code text, table_name text, deleted bigint) ON COMMIT DROP;

WITH d AS (
  DELETE FROM denomination_balance db
   USING fkh058_branch b
   WHERE db.cash_desk_id = b.branch_id AND db.submission_date < DATE '2026-09-01'
  RETURNING b.code
)
INSERT INTO fkh058_counts SELECT code, 'denomination_balance', count(*) FROM d GROUP BY code;

WITH d AS (
  DELETE FROM daily_balance db
   USING fkh058_branch b
   WHERE db.branch_id = b.branch_id
     AND db.company_id = '17015396-a878-4677-ab8e-05f2f7a8ee6c'
     AND db.balance_date < DATE '2026-09-01'
  RETURNING b.code
)
INSERT INTO fkh058_counts SELECT code, 'daily_balance', count(*) FROM d GROUP BY code;

-- closing_wizard_step has an ON DELETE NO ACTION FK to closing_wizard -> delete children first
WITH d AS (
  DELETE FROM closing_wizard_step s
   USING closing_wizard cw, fkh058_branch b
   WHERE s.wizard_id = cw.id AND cw.branch_id = b.branch_id
     AND cw.closing_date < DATE '2026-09-01'
  RETURNING b.code
)
INSERT INTO fkh058_counts SELECT code, 'closing_wizard_step', count(*) FROM d GROUP BY code;

WITH d AS (
  DELETE FROM closing_wizard cw
   USING fkh058_branch b
   WHERE cw.branch_id = b.branch_id AND cw.closing_date < DATE '2026-09-01'
  RETURNING b.code
)
INSERT INTO fkh058_counts SELECT code, 'closing_wizard', count(*) FROM d GROUP BY code;

WITH d AS (
  DELETE FROM closing_control cc
   USING fkh058_branch b
   WHERE cc.branch_id = b.branch_id
     AND cc.company_id = '17015396-a878-4677-ab8e-05f2f7a8ee6c'
     AND cc.control_date < DATE '2026-09-01'
  RETURNING b.code
)
INSERT INTO fkh058_counts SELECT code, 'closing_control', count(*) FROM d GROUP BY code;

WITH d AS (
  DELETE FROM daily_session ds
   USING fkh058_branch b
   WHERE ds.branch_id = b.branch_id
     AND ds.company_id = '17015396-a878-4677-ab8e-05f2f7a8ee6c'
     AND ds.session_date < DATE '2026-09-01'
  RETURNING b.code
)
INSERT INTO fkh058_counts SELECT code, 'daily_session', count(*) FROM d GROUP BY code;

-- FR-6: one dedicated audit_log entry per affected branch
INSERT INTO audit_log (id, action, entity_type, entity_id, created_at, ts,
                       branch_id, branch_name, company_id,
                       user_id, user_name, worker_role, reason, changes, new_value)
SELECT gen_random_uuid(),
       'FKH058_TEST_DATA_PURGE',
       'DailySession',
       b.branch_id::text,
       NOW(), NOW(),
       b.branch_id::text, b.name,
       '17015396-a878-4677-ab8e-05f2f7a8ee6c',
       'developer-dba', 'Fejleszto/DBA', 'DEVELOPER',
       'FKH-058 executed under FKH-059 FR-2: pre-2026-09-01 test data purge, human-approved (NFR-3)',
       'branch=' || b.code || '; range=session_date/balance_date/submission_date/closing_date/control_date < 2026-09-01; deleted=' ||
       COALESCE((SELECT string_agg(c.table_name || ':' || c.deleted, ', ' ORDER BY c.table_name)
                 FROM fkh058_counts c WHERE c.branch_code = b.code), 'none') ||
       '; backup=/root/fkh058-backup/*.csv',
       'DELETED'
  FROM fkh058_branch b;

SELECT branch_code, table_name, deleted FROM fkh058_counts ORDER BY branch_code, table_name;

COMMIT;
