-- V25: Audit log rendszer bővítés
-- Érzékeny műveletekhez: supervisor override, stornó, árfolyam változás, stb.
-- A meglévő audit_log tábla bővítése oldValue/newValue JSON mezőkkel és reason-nel

ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS old_value TEXT;
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS new_value TEXT;
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS reason VARCHAR(1000);

-- Indexek a hatékony lekérdezésekhez
CREATE INDEX IF NOT EXISTS idx_audit_log_entity_id ON audit_log(entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_user_id ON audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_branch_id ON audit_log(branch_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON audit_log(action);
CREATE INDEX IF NOT EXISTS idx_audit_log_created ON audit_log(created_at DESC);
