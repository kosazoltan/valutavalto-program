-- V152: ADMIN worker -> ugyvezeto canonical role hozzarendelese
-- Hiba felfedezese (2026-04-20 E2E audit): a bootstrap-adminBootstrapService
-- letrehozza az ADMIN-t legacy worker.role = 'ADMIN' mezovel, de a V57
-- canonical role-rendszerben (worker_role_assignment) NINCS bejegyzes.
-- Ezert a menuGroups.ts hasCanonicalRole() szuro mindent kiszur.
-- Fix: idempotens INSERT az ugyvezeto canonicalRole hozzarendelesere.

INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, rd.id, true
FROM worker w
CROSS JOIN worker_role_def rd
WHERE w.role = 'ADMIN'
  AND rd.code = 'ugyvezeto'
  AND NOT EXISTS (
      SELECT 1 FROM worker_role_assignment wra
      WHERE wra.worker_id = w.id AND wra.role_def_id = rd.id
  );
