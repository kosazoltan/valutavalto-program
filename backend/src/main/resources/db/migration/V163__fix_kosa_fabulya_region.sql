-- V163: KOSA + FABULYA region beallitas.
--
-- A V162 migration felvette a KOSA-t es FABULYA-t, de a worker.region mezo
-- ures maradt. A PublicBranchController.getPublicWorkersByBranch a workers-t
-- `region` alapon szuri (region == branch.region), tehat ures region-nel
-- a dropdown-bol eltunnek.
--
-- Javitas: regit a branch.region-bol masoljuk at.

UPDATE worker w
SET region = b.region
FROM branch b
WHERE w.branch_id = b.id
  AND w.code IN ('KOSA', 'FABULYA')
  AND (w.region IS NULL OR w.region = '');

DO $$
DECLARE
    updated INT;
BEGIN
    SELECT COUNT(*) INTO updated
    FROM worker
    WHERE code IN ('KOSA', 'FABULYA') AND region IS NOT NULL;
    RAISE NOTICE 'V163: % worker region beirva', updated;
END
$$;