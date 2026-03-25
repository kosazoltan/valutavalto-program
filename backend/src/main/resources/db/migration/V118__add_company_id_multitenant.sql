-- V118: Add company_id column for multi-tenant filtering
-- These tables had findAll() without company filtering (security audit fix)

ALTER TABLE anonymous_report ADD COLUMN IF NOT EXISTS company_id UUID;
ALTER TABLE authorized_representative ADD COLUMN IF NOT EXISTS company_id UUID;
ALTER TABLE prohibited_person ADD COLUMN IF NOT EXISTS company_id UUID;
ALTER TABLE prohibited_company ADD COLUMN IF NOT EXISTS company_id UUID;
ALTER TABLE handover_sheet ADD COLUMN IF NOT EXISTS company_id UUID;
ALTER TABLE receipt ADD COLUMN IF NOT EXISTS company_id UUID;
ALTER TABLE organization ADD COLUMN IF NOT EXISTS company_id UUID;
ALTER TABLE own_company ADD COLUMN IF NOT EXISTS company_id UUID;

-- Indexes for tenant-scoped queries
CREATE INDEX IF NOT EXISTS idx_anonymous_report_company_id ON anonymous_report(company_id);
CREATE INDEX IF NOT EXISTS idx_authorized_representative_company_id ON authorized_representative(company_id);
CREATE INDEX IF NOT EXISTS idx_prohibited_person_company_id ON prohibited_person(company_id);
CREATE INDEX IF NOT EXISTS idx_prohibited_company_company_id ON prohibited_company(company_id);
CREATE INDEX IF NOT EXISTS idx_handover_sheet_company_id ON handover_sheet(company_id);
CREATE INDEX IF NOT EXISTS idx_receipt_company_id ON receipt(company_id);
CREATE INDEX IF NOT EXISTS idx_organization_company_id ON organization(company_id);
CREATE INDEX IF NOT EXISTS idx_own_company_company_id ON own_company(company_id);

-- Backfill existing records with the first company (single-tenant assumption)
DO $$
DECLARE
    default_company_id UUID;
BEGIN
    SELECT id INTO default_company_id FROM company LIMIT 1;
    IF default_company_id IS NOT NULL THEN
        UPDATE anonymous_report SET company_id = default_company_id WHERE company_id IS NULL;
        UPDATE authorized_representative SET company_id = default_company_id WHERE company_id IS NULL;
        UPDATE prohibited_person SET company_id = default_company_id WHERE company_id IS NULL;
        UPDATE prohibited_company SET company_id = default_company_id WHERE company_id IS NULL;
        UPDATE handover_sheet SET company_id = default_company_id WHERE company_id IS NULL;
        UPDATE receipt SET company_id = default_company_id WHERE company_id IS NULL;
        UPDATE organization SET company_id = default_company_id WHERE company_id IS NULL;
        UPDATE own_company SET company_id = default_company_id WHERE company_id IS NULL;
    END IF;
END $$;
