-- V195: Fix for V194 — correct column name: assigned_at (not created_at)
-- V194 failed on production because worker_role_assignment.created_at does not exist.
-- The repair workflow deletes the failed V194 entry from flyway_schema_history,
-- so this V195 performs the same INSERT with the correct column name.

INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary, assigned_at)
SELECT w.id, rd.id, false, NOW()
FROM worker w
JOIN worker_role_def rd ON rd.code = 'foertektar'
WHERE w.code = 'KOSA'
  AND NOT EXISTS (
    SELECT 1 FROM worker_role_assignment wra
    WHERE wra.worker_id = w.id AND wra.role_def_id = rd.id
  );

INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary, assigned_at)
SELECT w.id, rd.id, false, NOW()
FROM worker w
JOIN worker_role_def rd ON rd.code = 'belso_ellenor'
WHERE w.code = 'KOSA'
  AND NOT EXISTS (
    SELECT 1 FROM worker_role_assignment wra
    WHERE wra.worker_id = w.id AND wra.role_def_id = rd.id
  );
