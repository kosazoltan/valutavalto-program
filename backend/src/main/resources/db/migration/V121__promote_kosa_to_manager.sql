-- V120: Promote KOSA worker to MANAGER role for full business flow testing
-- This allows rate creation, approval, transfers, and other supervisor+ operations.

UPDATE worker
SET role = 'MANAGER',
    updated_at = NOW()
WHERE code = 'KOSA'
  AND company_id = (SELECT id FROM company WHERE code = 'EBC' LIMIT 1);
