-- FS-15 UZLETKOTES: központi fixing-igény modul (user-döntés 2026-07-11).
-- FK constraint szándékosan NINCS (V350/V353/V354 precedens); UNIQUE index véd.
CREATE TABLE IF NOT EXISTS darius_bank_branch (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    company_id UUID NOT NULL,
    bank_branch_code VARCHAR(50) NOT NULL,
    name VARCHAR(200) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_dbb_company_code
    ON darius_bank_branch (company_id, bank_branch_code);

CREATE TABLE IF NOT EXISTS darius_fixing_request (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    company_id UUID NOT NULL,
    bank_branch_id UUID NOT NULL,
    request_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL,
    note VARCHAR(500),
    created_by VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    approved_by VARCHAR(100),
    approved_at TIMESTAMP,
    cancelled_by VARCHAR(100),
    cancelled_at TIMESTAMP,
    included_at TIMESTAMP,
    included_file_sha256 VARCHAR(64),
    updated_at TIMESTAMP
);
CREATE INDEX IF NOT EXISTS ix_dfr_company_date
    ON darius_fixing_request (company_id, request_date);
-- Élő (nem visszavont) igényből (cég, nap, bankfiók) hármasra legfeljebb egy lehet:
CREATE UNIQUE INDEX IF NOT EXISTS ux_dfr_company_date_branch_live
    ON darius_fixing_request (company_id, request_date, bank_branch_id)
    WHERE status <> 'CANCELLED';

-- Tenant defense-in-depth (korrekció 2026-07-11): a sor is hordozza a company_id-t,
-- minden elérés companyId-szkópolt — nem csak a szülő igényen át védett.
CREATE TABLE IF NOT EXISTS darius_fixing_request_line (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    company_id UUID NOT NULL,
    request_id UUID NOT NULL,
    currency_code VARCHAR(3) NOT NULL,
    delivered_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
    collected_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
    CONSTRAINT uq_dfrl_company_request_currency UNIQUE (company_id, request_id, currency_code)
);
CREATE INDEX IF NOT EXISTS ix_dfrl_company_request
    ON darius_fixing_request_line (company_id, request_id);
