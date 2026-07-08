-- FS-11 S2b: compliance keresés-audit napló — a keresés pillanatának jogi snapshotja.
-- Új tábla (nincs ALTER — PROD-502). FK szándékosan NINCS (V350 precedens).
-- IMMUTABLE tartalom: az alkalmazás nem ad update-utat, az entitás @Immutable.
CREATE TABLE IF NOT EXISTS compliance_search_audit (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    company_id UUID NOT NULL,
    title VARCHAR(200) NOT NULL,
    description VARCHAR(2000),
    criteria_json JSONB NOT NULL,
    result_snapshot_json JSONB NOT NULL,
    result_count INTEGER NOT NULL,
    created_by_worker_code VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
-- Cég-szkópú lista időrendben (a (company_id, created_at) prefix a cég-scan indexe is).
CREATE INDEX IF NOT EXISTS ix_csa_company_created
    ON compliance_search_audit (company_id, created_at DESC);
