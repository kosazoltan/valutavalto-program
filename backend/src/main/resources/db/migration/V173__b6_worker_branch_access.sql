-- v2.4.0 (B6 audit fix) — Multi-branch worker access table
--
-- Audit B6: a SetupWizard branch-választás IGNORE-olva volt (worker.branchId
-- override-olta a wizard-választást). Ennek root-cause: 1 worker → 1 fix branch.
-- Megoldás: új M:N kapcsolat worker × branch — engedélyezett branch-list per
-- worker. A SetupWizard branchId mostantól egy "branchOverride" lesz, amit a
-- backend a worker_branch_access alapján validál.
--
-- Iparágí pattern (OWASP A01 multi-tenant):
-- - Defense-in-depth: NEM csak a JWT branchOverride-en alapul, hanem
--   `worker_branch_access` szintű explicit grant-ekre.
-- - Default deny: ha nincs explicit access record, NEM lehet az override branch-en
--   tranzakciót rögzíteni.
-- - Audit trail: granted_by_worker_id + granted_at — ki engedélyezte mikor.
--
-- Backward compat:
-- - Minden meglévő worker default branch-éhez (worker.branchId) egy
--   worker_branch_access rekord seed-elődik (1:1 backward compat).
-- - A v2.3.X-es kliensek továbbra is működnek (a JWT branchOverride opcionális,
--   ha NULL → fallback a worker.branchId-ra).
--
-- Felhasználó-döntés: user-direktíva 2026-04-30 06:15 CEST — "C-1: Yes (multi-branch enabled)"
-- → engedélyezett a multi-branch worker pattern, admin UI a v2.4.0-ban érkezik.

CREATE TABLE IF NOT EXISTS worker_branch_access (
    worker_id BIGINT NOT NULL REFERENCES worker(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branch(id) ON DELETE CASCADE,
    granted_at TIMESTAMP NOT NULL DEFAULT NOW(),
    granted_by_worker_id BIGINT REFERENCES worker(id) ON DELETE SET NULL,
    PRIMARY KEY (worker_id, branch_id)
);

-- Index per-worker lookup (a leggyakoribb JWT-validation query)
CREATE INDEX IF NOT EXISTS idx_worker_branch_access_worker_id
    ON worker_branch_access(worker_id);

-- Backward compat seed: minden meglévő worker default branchId → 1 record
-- granted_by_worker_id = self (system-seed, NEM ember által)
INSERT INTO worker_branch_access (worker_id, branch_id, granted_at, granted_by_worker_id)
SELECT w.id, w.branch_id, NOW(), w.id
FROM worker w
WHERE w.branch_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM worker_branch_access wba
      WHERE wba.worker_id = w.id AND wba.branch_id = w.branch_id
  );

-- Audit log (DB-szintű, csak NOTICE — production-ban INFO-szintű audit-ot a
-- WorkerBranchAccessService log-ja ad)
DO $$
DECLARE
    v_seeded INT;
BEGIN
    SELECT COUNT(*) INTO v_seeded FROM worker_branch_access;
    RAISE NOTICE 'V173 B6 multi-branch foundation: % worker_branch_access record', v_seeded;
END $$;

-- Comment for future maintainers
COMMENT ON TABLE worker_branch_access IS
'v2.4.0 B6 multi-branch worker access table. M:N relation worker × branch. '
'A SetupWizard branchOverride a JWT-be kerül, és a backend a '
'WorkerBranchAccessService.hasAccess(workerId, branchId) ellenőrzéssel '
'engedélyezi a tranzakció-rögzítést. Default seed: 1:1 worker.branchId backward compat.';

COMMENT ON COLUMN worker_branch_access.granted_by_worker_id IS
'Aki engedélyezte a hozzáférést (NULL ha system-seed vagy törölt admin). '
'Audit-trail: ki adta meg az engedélyt mikor (granted_at).';
