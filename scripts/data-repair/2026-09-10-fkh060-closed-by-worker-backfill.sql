-- FKH-060 FR-5 (SHOULD): backfill daily_session.closed_by_worker_id from a COMPLETED
-- ClosingWizard.completed_by_worker for the same branch+date, only where the session
-- looks FALSE_CLOSED (CLOSED + worker NULL + not retroactive).
-- Company-scoped. Append-only audit_log (do NOT UPDATE existing audit rows).
-- Human approval required before running against live data (NFR-2 backup first).
-- NOT a Flyway migration.
\set ON_ERROR_STOP on
BEGIN;

CREATE TEMP TABLE fkh060_targets AS
SELECT ds.id AS session_id,
       ds.branch_id,
       ds.company_id,
       ds.session_date,
       cw.completed_by_worker_id AS worker_id
  FROM daily_session ds
  JOIN closing_wizard cw
    ON cw.branch_id = ds.branch_id
   AND cw.closing_date = ds.session_date
   AND cw.wizard_status = 'COMPLETED'
   AND cw.completed_by_worker_id IS NOT NULL
 WHERE ds.status = 'CLOSED'
   AND ds.closed_by_worker_id IS NULL
   AND (ds.is_retroactive_closing IS NULL OR ds.is_retroactive_closing = FALSE);

UPDATE daily_session ds
   SET closed_by_worker_id = t.worker_id
  FROM fkh060_targets t
 WHERE ds.id = t.session_id
   AND ds.closed_by_worker_id IS NULL
   AND ds.status = 'CLOSED'
   AND ds.company_id = t.company_id;

INSERT INTO audit_log (id, action, entity_type, entity_id, created_at, ts,
                       company_id, user_id, user_name, worker_role, reason, changes, new_value)
SELECT gen_random_uuid(),
       'FKH060_CLOSED_BY_WORKER_BACKFILL',
       'DailySession',
       'batch',
       NOW(), NOW(),
       (SELECT company_id FROM fkh060_targets LIMIT 1),
       'developer-dba', 'Fejleszto/DBA', 'DEVELOPER',
       'FKH-060 FR-5: backfill closed_by_worker_id from COMPLETED closing_wizard',
       'rows=' || (SELECT count(*) FROM fkh060_targets)::text
         || '; dates=' || COALESCE((SELECT string_agg(session_date::text, ',' ORDER BY session_date)
                                    FROM fkh060_targets), 'none'),
       'BACKFILL'
 WHERE EXISTS (SELECT 1 FROM fkh060_targets);

SELECT count(*) AS backfilled FROM fkh060_targets;

COMMIT;
