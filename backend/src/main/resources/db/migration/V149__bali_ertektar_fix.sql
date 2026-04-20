-- V149: Legacy V110/V111 seed munkakor-javitas az EBC xlsx munkakor oszlopa alapjan
-- User visszajelzes: "bali ertektar". Ellenorizve az xlsx-ben:
--   BALI (V111 seed "Bali Henrietta") -> Ertektaros (Szeged regio)
--   BORSI ("Borsi Tamas") -> Foertektaros (Szeged regio) - V148-ban mar javitva
--   KASZA ("Kasza Helga") -> Foertektaros (Szeged regio) - V148-ban mar javitva
--   KOSA ("Kosa Zoltan") -> Ugyvezeto (Iroda) - V147-ben mar javitva
-- A V111 seed tevesen CASHIER role-lal sorolta mindet, a V147 a legacy
-- BORSI/BALI/KASZA-t 'penztar' role_def-hez rendelte, ez nem korrekt.

-- 1. BALI = ertektar (SUPERVISOR legacy enum)
UPDATE worker SET role = 'SUPERVISOR' WHERE code = 'BALI'
  AND company_id = (SELECT id FROM company WHERE code = 'EBC');

DELETE FROM worker_role_assignment
WHERE worker_id = (SELECT id FROM worker WHERE code = 'BALI' AND company_id = (SELECT id FROM company WHERE code = 'EBC'));

INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'BALI' AND r.code = 'ertektar'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC')
ON CONFLICT DO NOTHING;

-- 2. BORSI + KASZA: penztar secondary role_def_assignment eltavolitasa
-- (V148 primary=foertektar-ra allitotta oket, de a penztar secondary megmaradt,
-- ami hibas - foertektarosok nem penztarosok az xlsx szerint)
DELETE FROM worker_role_assignment
WHERE worker_id IN (
  SELECT id FROM worker WHERE code IN ('BORSI','KASZA')
    AND company_id = (SELECT id FROM company WHERE code = 'EBC')
)
AND role_def_id = (SELECT id FROM worker_role_def WHERE code = 'penztar');
