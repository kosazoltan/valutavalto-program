-- V262: Okmányhiány-regiszter (legacy OKMANYHIANY / OKMCTRL.dll)
-- Hiányos/hiányzó okmánnyal rögzített tranzakciók követő-listája. Multi-tenant.

CREATE TABLE IF NOT EXISTS document_shortage (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id       UUID NOT NULL REFERENCES company(id),
    branch_code      VARCHAR(20),
    customer_id      VARCHAR(50),
    customer_name    VARCHAR(200),
    receipt_number   VARCHAR(50),
    missing_document VARCHAR(200) NOT NULL,
    note             TEXT,
    recorded_by      VARCHAR(100),
    recorded_at      TIMESTAMP DEFAULT now(),
    resolved_at      TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_doc_shortage_company ON document_shortage (company_id);
CREATE INDEX IF NOT EXISTS idx_doc_shortage_branch ON document_shortage (company_id, branch_code);
