-- V206: TH (tobblet-hiany) penztartipus dictionary bejegyzes
-- A TransferPage branch dropdown szureshez szukseges: csak ertektar + TH valaszthato

INSERT INTO dictionary (id, category, code, name, description, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'BRANCH_TYPE', 'TH', 'Tobblet-hiany', 'Tobblet-hiany penztar', 5, true, NOW())
ON CONFLICT (category, code) DO NOTHING;
