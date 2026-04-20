-- V148: Borsi Tamas + Kasza Helga foertektar fix
-- Az xlsx-ben mindketten "Főértéktáros" munkakorrel szerepelnek, de a V146 dedup
-- deaktivalta a V145-bol szarmazo W-S012 (Borsi) + W-S085 (Kasza) duplikatumokat.
-- A V147 a legacy BORSI/KASZA kodokat penztar role-hoz rendelte.
-- V148: penztar-t kulon-kulon tartjuk (history), es hozzaadjuk a foertektar-t primary-kent.

-- BORSI: foertektar primary + penztar secondary
UPDATE worker_role_assignment SET is_primary = false
WHERE worker_id = (SELECT id FROM worker WHERE code = 'BORSI' AND company_id = (SELECT id FROM company WHERE code = 'EBC'))
  AND role_def_id = (SELECT id FROM worker_role_def WHERE code = 'penztar');

INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'BORSI' AND r.code = 'foertektar'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC')
ON CONFLICT (worker_id, role_def_id) DO UPDATE SET is_primary = true;

-- KASZA: foertektar primary + penztar secondary
UPDATE worker_role_assignment SET is_primary = false
WHERE worker_id = (SELECT id FROM worker WHERE code = 'KASZA' AND company_id = (SELECT id FROM company WHERE code = 'EBC'))
  AND role_def_id = (SELECT id FROM worker_role_def WHERE code = 'penztar');

INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, r.id, true FROM worker w, worker_role_def r
WHERE w.code = 'KASZA' AND r.code = 'foertektar'
  AND w.company_id = (SELECT id FROM company WHERE code = 'EBC')
ON CONFLICT (worker_id, role_def_id) DO UPDATE SET is_primary = true;

-- Legacy worker.role enum: BORSI + KASZA = MANAGER (foertektarosok, nem sima penztarosok)
UPDATE worker SET role = 'MANAGER' WHERE code IN ('BORSI','KASZA')
  AND company_id = (SELECT id FROM company WHERE code = 'EBC');
