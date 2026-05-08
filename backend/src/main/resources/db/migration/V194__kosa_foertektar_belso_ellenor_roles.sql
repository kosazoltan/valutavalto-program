-- V194: Assign foertektar + belso_ellenor roles to KOSA worker
-- User directive 2026-05-08: admin must choose between ugyvezeto, foertektar, belso_ellenor at login

INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary, created_at)
SELECT w.id, rd.id, false, NOW()
FROM worker w
JOIN worker_role_def rd ON rd.code = 'foertektar'
WHERE w.code = 'KOSA'
  AND NOT EXISTS (
    SELECT 1 FROM worker_role_assignment wra
    WHERE wra.worker_id = w.id AND wra.role_def_id = rd.id
  );

INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary, created_at)
SELECT w.id, rd.id, false, NOW()
FROM worker w
JOIN worker_role_def rd ON rd.code = 'belso_ellenor'
WHERE w.code = 'KOSA'
  AND NOT EXISTS (
    SELECT 1 FROM worker_role_assignment wra
    WHERE wra.worker_id = w.id AND wra.role_def_id = rd.id
  );
