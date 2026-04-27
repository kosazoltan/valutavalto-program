-- V164: Multi-tenant scoping for cash_desk_break
-- ROOT CAUSE: cash_desk_break.cash_desk_id is a free UUID (no FK to a cash_desk table),
-- and the entity had no company_id column. CashDeskBreakService.listBreaks(null)
-- returned breaks across ALL tenants. AUDIT FINDING (P0, 2026-04-27).
--
-- FIX: add company_id column (NOT NULL on all NEW rows; NULL allowed on existing rows
-- for forward-only deployment). The Java entity enforces NOT NULL on all new inserts,
-- and the repository queries WHERE company_id = :companyId — this means any pre-existing
-- rows with NULL company_id become invisible (intentional: stale data is preferable to
-- a tenant leak).
--
-- A follow-up migration may TRUNCATE NULL company_id rows + SET NOT NULL after a soak
-- period.

-- Add nullable column (forward-only safe)
ALTER TABLE cash_desk_break
    ADD COLUMN IF NOT EXISTS company_id UUID;

-- FK to company (nullable side)
ALTER TABLE cash_desk_break
    ADD CONSTRAINT fk_cash_desk_break_company
    FOREIGN KEY (company_id) REFERENCES company(id) ON DELETE RESTRICT;

-- Composite index for common query path (company_id, cash_desk_id, break_start desc)
CREATE INDEX IF NOT EXISTS idx_cash_desk_break_company
    ON cash_desk_break(company_id, cash_desk_id, break_start DESC);

-- Partial index for active break lookup
CREATE INDEX IF NOT EXISTS idx_cash_desk_break_company_active
    ON cash_desk_break(company_id, cash_desk_id)
    WHERE is_active = TRUE;

COMMENT ON COLUMN cash_desk_break.company_id IS
    'Multi-tenant scope (V164, audit-NO-GO-iter3 P0 fix). NULL only on legacy rows; new rows always set by CashDeskBreakService.';
