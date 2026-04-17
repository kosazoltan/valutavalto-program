-- V25: Audit log rendszer bővítés
-- Érzékeny műveletekhez: supervisor override, stornó, árfolyam változás, stb.
-- A meglévő audit_log tábla bővítése oldValue/newValue JSON mezőkkel és reason-nel
--
-- NOTE: Production DBs (baseline=67) never execute V25, mert V25 < baseline.
-- A régi audit_log táblát ott Hibernate ddl-auto=update hozta létre; V74 utólag
-- tette explicitté. Friss (local) DB-n V25 a V74 előtt futna, ezért itt
-- idempotensen létrehozzuk az alap táblát (V74-tel azonos sémával), így
-- az ALTER-ek biztosan sikeresek lesznek akkor is, ha a tábla még nem létezik.

CREATE TABLE IF NOT EXISTS audit_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action          VARCHAR(50)  NOT NULL,
    entity_type     VARCHAR(50)  NOT NULL,
    entity_id       VARCHAR(50),
    user_id         VARCHAR(50),
    user_name       VARCHAR(100),
    branch_id       VARCHAR(50),
    branch_name     VARCHAR(100),
    changes         TEXT,
    ip_address      VARCHAR(50),
    user_agent      VARCHAR(500),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS old_value TEXT;
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS new_value TEXT;
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS reason VARCHAR(1000);

-- Indexek a hatékony lekérdezésekhez
CREATE INDEX IF NOT EXISTS idx_audit_log_entity_id ON audit_log(entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_user_id ON audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_branch_id ON audit_log(branch_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON audit_log(action);
CREATE INDEX IF NOT EXISTS idx_audit_log_created ON audit_log(created_at DESC);
