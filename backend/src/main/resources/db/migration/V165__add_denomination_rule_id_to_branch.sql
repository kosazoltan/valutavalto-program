-- V165: branch.denomination_rule_id guard migration
-- A Branch.java entitás hivatkozik erre az oszlopra, de korábbi migrációkban nem volt létrehozva.
-- Nullable UUID oszlop (nincs FK-ja amíg a denomination_rule tábla nem létezik).
ALTER TABLE public.branch ADD COLUMN IF NOT EXISTS denomination_rule_id UUID;
