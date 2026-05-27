-- V270: police_request multi-tenant scope — company_id oszlop + backfill.
--
-- Architect-mode audit (2026-05-27): a police_request entitásnak NEM volt company_id-ja, ezért a
-- PoliceRequestService.getRequest / getRequestHistory / processRequest minden cég rendőrségi
-- adatkérését visszaadta (MANAGER/ADMIN-gated, de cross-tenant adatszivárgás: rendőrségi/ügyfél-
-- találati adat más cégtől). A többi entitás company_id-vel scope-olt; ez a hiányzó párja.
--
-- Backfill: a létrehozó dolgozó (created_by) fiókjának cégéből vezetjük le. A police_request.created_by
-- → worker.id → worker.branch_id → branch.company_id láncon. Dolgozó nélküli (created_by IS NULL) árva
-- sorok company_id-ja NULL marad → a scope-olt query egyik tenantnak sem mutatja (fail-closed).

ALTER TABLE police_request ADD COLUMN IF NOT EXISTS company_id UUID;

UPDATE police_request pr
SET company_id = b.company_id
FROM worker w
JOIN branch b ON w.branch_id = b.id
WHERE pr.created_by = w.id
  AND pr.company_id IS NULL;

-- FK a company-ra (nullable oszlop → a NULL árva sorok megengedettek). Idempotens guard.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_police_request_company'
    ) THEN
        ALTER TABLE police_request
            ADD CONSTRAINT fk_police_request_company
            FOREIGN KEY (company_id) REFERENCES company(id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_police_request_company_created
    ON police_request (company_id, created_at);
