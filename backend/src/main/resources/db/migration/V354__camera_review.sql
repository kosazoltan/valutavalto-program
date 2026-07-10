-- FS-14: kamera-ellenőri megjelölések + napi átnézve-státusz.
-- Új táblák (nincs ALTER — PROD-502). FK szándékosan nincs (V350/V351 precedens).
CREATE TABLE IF NOT EXISTS camera_review_mark (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    company_id UUID NOT NULL,
    branch_id UUID NOT NULL,
    review_date DATE NOT NULL,
    camera_id VARCHAR(50) NOT NULL,
    mark_time TIME NOT NULL,
    opening_closing_ok BOOLEAN NOT NULL,
    invoices_ok BOOLEAN NOT NULL,
    breaks_ok BOOLEAN NOT NULL,
    board_ok BOOLEAN NOT NULL,
    curtain_ok BOOLEAN NOT NULL,
    note VARCHAR(500),
    created_by_worker_id BIGINT NOT NULL,
    created_by_worker_code VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMP,
    deleted_by_worker_id BIGINT
);

CREATE INDEX IF NOT EXISTS ix_crm_company_branch_date
    ON camera_review_mark (company_id, branch_id, review_date);

CREATE TABLE IF NOT EXISTS camera_review_status (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    company_id UUID NOT NULL,
    branch_id UUID NOT NULL,
    review_date DATE NOT NULL,
    reviewed BOOLEAN NOT NULL DEFAULT FALSE,
    reviewed_by_worker_id BIGINT,
    reviewed_by_worker_code VARCHAR(50),
    reviewed_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_crs_company_branch_date UNIQUE (company_id, branch_id, review_date)
);
