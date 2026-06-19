ALTER TABLE password_reset_token
    ADD COLUMN IF NOT EXISTS company_id UUID;

UPDATE password_reset_token prt
SET company_id = w.company_id
FROM worker w
WHERE prt.worker_id = w.id
  AND prt.company_id IS NULL;

CREATE INDEX IF NOT EXISTS idx_password_reset_company_worker_active
    ON password_reset_token (company_id, worker_id, used_at, expires_at);
