-- FS-11 S2a: mentett compliance szűrő-sablonok, cégenként közösek.
-- Új tábla (nincs ALTER — PROD-502). FK szándékosan NINCS (V346/V347 precedens,
-- típus-drift tanulság): UNIQUE + index véd.
CREATE TABLE IF NOT EXISTS compliance_search_template (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    company_id UUID NOT NULL,
    name VARCHAR(100) NOT NULL,
    criteria_json JSONB NOT NULL,
    created_by_worker_code VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
-- Egy néven egy sablon cégenként (D2); a (company_id, ...) prefix a cég-scan indexe is.
CREATE UNIQUE INDEX IF NOT EXISTS ux_cst_company_name
    ON compliance_search_template (company_id, name);
