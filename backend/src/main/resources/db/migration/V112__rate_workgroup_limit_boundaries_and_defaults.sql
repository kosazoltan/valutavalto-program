-- V112: rate_workgroup limit boundary compatibility + default workgroup/branch links

-- 1) Missing limit boundary columns for RateCreationService / RateWorkgroup entity
ALTER TABLE rate_workgroup ADD COLUMN IF NOT EXISTS limit1_boundary NUMERIC(15,2);
ALTER TABLE rate_workgroup ADD COLUMN IF NOT EXISTS limit2_boundary NUMERIC(15,2);
ALTER TABLE rate_workgroup ADD COLUMN IF NOT EXISTS limit3_boundary NUMERIC(15,2);

UPDATE rate_workgroup
SET
    limit1_boundary = COALESCE(limit1_boundary, 50000),
    limit2_boundary = COALESCE(limit2_boundary, 300000),
    limit3_boundary = COALESCE(limit3_boundary, 1000000)
WHERE limit1_boundary IS NULL
   OR limit2_boundary IS NULL
   OR limit3_boundary IS NULL;

ALTER TABLE rate_workgroup ALTER COLUMN limit1_boundary SET DEFAULT 50000;
ALTER TABLE rate_workgroup ALTER COLUMN limit2_boundary SET DEFAULT 300000;
ALTER TABLE rate_workgroup ALTER COLUMN limit3_boundary SET DEFAULT 1000000;

-- 2) Ensure at least one active workgroup per company
INSERT INTO rate_workgroup (
    id, company_id, name, code, legacy_group_number, active, created_at,
    limit1_boundary, limit2_boundary, limit3_boundary
)
SELECT
    gen_random_uuid(),
    c.id,
    'Alap munkacsoport',
    CONCAT('WG-', UPPER(SUBSTRING(REPLACE(c.id::text, '-', ''), 1, 6))),
    1,
    true,
    NOW(),
    50000,
    300000,
    1000000
FROM company c
WHERE NOT EXISTS (
    SELECT 1 FROM rate_workgroup rw WHERE rw.company_id = c.id
);

-- 3) If a workgroup has no branch assignment, assign active branches from same company
INSERT INTO rate_workgroup_branch (workgroup_id, branch_id)
SELECT rw.id, b.id
FROM rate_workgroup rw
JOIN branch b ON b.company_id = rw.company_id
WHERE rw.active = true
  AND COALESCE(b.is_active, true) = true
  AND NOT EXISTS (
      SELECT 1 FROM rate_workgroup_branch rwb WHERE rwb.workgroup_id = rw.id
  )
ON CONFLICT DO NOTHING;
