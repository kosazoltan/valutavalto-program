-- V150: 28 permission seed + worker_role_permission az EBCiroda kanonikus role_def kodokra
-- V57 production baseline 67 elott volt, permission + worker_role_permission nem feltoltve
-- V147 csak a worker_role_def-et. V150 kiegesziti.

-- 1. 28 permission seed (idempotens)
INSERT INTO permission (id, code, name, description, module, is_system_permission, is_active, created_at) VALUES
  (gen_random_uuid(), 'TRANSACTION_BUY', 'Valuta vetel', 'Valuta vetel', 'TRANSACTION', true, true, NOW()),
  (gen_random_uuid(), 'TRANSACTION_SELL', 'Valuta eladas', 'Valuta eladas', 'TRANSACTION', true, true, NOW()),
  (gen_random_uuid(), 'TRANSACTION_WU', 'Western Union/Moneygram', 'Western Union/Moneygram', 'TRANSACTION', true, true, NOW()),
  (gen_random_uuid(), 'TRANSACTION_VAT_REFUND', 'AFA visszateritesa', 'AFA visszateritesa', 'TRANSACTION', true, true, NOW()),
  (gen_random_uuid(), 'TRANSFER_ACKNOWLEDGE', 'Atadas-atvetel elismeres', 'Atadas-atvetel elismeres', 'TRANSFER', true, true, NOW()),
  (gen_random_uuid(), 'TRANSFER_COURIER_PIN', 'Ertekszallito PIN kezeles', 'Ertekszallito PIN kezeles', 'TRANSFER', true, true, NOW()),
  (gen_random_uuid(), 'VAULT_RECEIVE', 'Ertektar: atvetel', 'Ertektar: atvetel', 'VAULT', true, true, NOW()),
  (gen_random_uuid(), 'VAULT_SEND', 'Ertektar: atadas', 'Ertektar: atadas', 'VAULT', true, true, NOW()),
  (gen_random_uuid(), 'VAULT_DAILY_CLOSE', 'Ertektari napi zaras', 'Ertektari napi zaras', 'VAULT', true, true, NOW()),
  (gen_random_uuid(), 'CASHIER_DAILY_CLOSE', 'Penztari napi zaras', 'Penztari napi zaras', 'CLOSING', true, true, NOW()),
  (gen_random_uuid(), 'RATE_CREATE', 'Arfolyam keszites', 'Arfolyam keszites', 'RATE', true, true, NOW()),
  (gen_random_uuid(), 'RATE_CUSTOM', 'Egyedi arfolyam', 'Egyedi arfolyam', 'RATE', true, true, NOW()),
  (gen_random_uuid(), 'STATS_VIEW', 'Statisztikak megtekintes', 'Statisztikak megtekintes', 'REPORTS', true, true, NOW()),
  (gen_random_uuid(), 'STATS_SUMMARY', 'Osszesitok keszites', 'Osszesitok keszites', 'REPORTS', true, true, NOW()),
  (gen_random_uuid(), 'REPORTS_BANK', 'Banki riportok', 'Banki riportok', 'REPORTS', true, true, NOW()),
  (gen_random_uuid(), 'PROFIT_VIEW', 'Haszonszamitas', 'Haszonszamitas', 'REPORTS', true, true, NOW()),
  (gen_random_uuid(), 'PRINT_ANY', 'Nyomtatas', 'Nyomtatas', 'PRINT', true, true, NOW()),
  (gen_random_uuid(), 'PRINT_TRIAL', 'Probanyomtatas', 'Probanyomtatas', 'PRINT', true, true, NOW()),
  (gen_random_uuid(), 'CAMERA_VIEW', 'Kamera megtekintes', 'Kamera megtekintes', 'CAMERA', true, true, NOW()),
  (gen_random_uuid(), 'CAMERA_DOWNLOAD', 'Kamera letoltes', 'Kamera letoltes', 'CAMERA', true, true, NOW()),
  (gen_random_uuid(), 'CAMERA_SETUP', 'Kamera beallitas', 'Kamera beallitas', 'CAMERA', true, true, NOW()),
  (gen_random_uuid(), 'AUDIT_CASHIER', 'Penztar rovancsolas', 'Penztar rovancsolas', 'AUDIT', true, true, NOW()),
  (gen_random_uuid(), 'AUDIT_VAULT', 'Ertektar rovancsolas', 'Ertektar rovancsolas', 'AUDIT', true, true, NOW()),
  (gen_random_uuid(), 'AUDIT_COURIER', 'Ertekszallito ellenorzes', 'Ertekszallito ellenorzes', 'AUDIT', true, true, NOW()),
  (gen_random_uuid(), 'SERVER_ACCESS', 'Szerver adatok letoltes', 'Szerver adatok letoltes', 'ADMIN', true, true, NOW()),
  (gen_random_uuid(), 'WORKER_MANAGE', 'Dolgozo kezeles', 'Dolgozo kezeles', 'ADMIN', true, true, NOW()),
  (gen_random_uuid(), 'TRANSACTION_VIEW_ONLY', 'Tranzakciok megtekintes', 'Tranzakciok megtekintes', 'TRANSACTION', true, true, NOW()),
  (gen_random_uuid(), 'VAULT_VIEW_ONLY', 'Ertektar megtekintes', 'Ertektar megtekintes', 'VAULT', true, true, NOW())
ON CONFLICT (code) DO NOTHING;

-- 2.1 penztar (V57 CASHIER)
INSERT INTO worker_role_permission (role_def_id, permission_id, access_level)
SELECT r.id, p.id, 'FULL' FROM worker_role_def r, permission p
WHERE r.code = 'penztar' AND p.code IN (
    'TRANSACTION_BUY', 'TRANSACTION_SELL', 'TRANSACTION_WU',
    'TRANSACTION_VAT_REFUND', 'TRANSFER_ACKNOWLEDGE',
    'CASHIER_DAILY_CLOSE', 'PRINT_ANY'
) ON CONFLICT DO NOTHING;

-- 2.2 ertekszallito (V57 COURIER)
INSERT INTO worker_role_permission (role_def_id, permission_id, access_level)
SELECT r.id, p.id, 'FULL' FROM worker_role_def r, permission p
WHERE r.code = 'ertekszallito' AND p.code IN ('TRANSFER_ACKNOWLEDGE')
ON CONFLICT DO NOTHING;

-- 2.3 ertektar (V57 VAULT_KEEPER)
INSERT INTO worker_role_permission (role_def_id, permission_id, access_level)
SELECT r.id, p.id, 'FULL' FROM worker_role_def r, permission p
WHERE r.code = 'ertektar' AND p.code IN (
    'VAULT_RECEIVE', 'VAULT_SEND', 'VAULT_DAILY_CLOSE',
    'TRANSFER_ACKNOWLEDGE', 'RATE_CUSTOM', 'STATS_VIEW',
    'STATS_SUMMARY', 'PRINT_ANY', 'PROFIT_VIEW', 'TRANSACTION_VIEW_ONLY'
) ON CONFLICT DO NOTHING;

-- 2.4 foertektar (V57 CHIEF_VAULT)
INSERT INTO worker_role_permission (role_def_id, permission_id, access_level)
SELECT r.id, p.id, 'FULL' FROM worker_role_def r, permission p
WHERE r.code = 'foertektar' AND p.code IN (
    'VAULT_RECEIVE', 'VAULT_SEND', 'VAULT_DAILY_CLOSE',
    'TRANSFER_ACKNOWLEDGE', 'RATE_CREATE', 'RATE_CUSTOM',
    'STATS_VIEW', 'STATS_SUMMARY', 'REPORTS_BANK', 'PROFIT_VIEW',
    'PRINT_ANY', 'SERVER_ACCESS', 'TRANSACTION_VIEW_ONLY', 'CASHIER_DAILY_CLOSE'
) ON CONFLICT DO NOTHING;

-- 2.5 teruleti_vezeto (V57 REGIONAL_MGR)
INSERT INTO worker_role_permission (role_def_id, permission_id, access_level)
SELECT r.id, p.id, 'FULL' FROM worker_role_def r, permission p
WHERE r.code = 'teruleti_vezeto' AND p.code IN (
    'TRANSACTION_VIEW_ONLY', 'VAULT_VIEW_ONLY', 'TRANSFER_ACKNOWLEDGE',
    'TRANSFER_COURIER_PIN', 'RATE_CUSTOM', 'STATS_VIEW', 'STATS_SUMMARY',
    'REPORTS_BANK', 'PROFIT_VIEW', 'PRINT_ANY', 'CAMERA_VIEW',
    'CAMERA_DOWNLOAD', 'CAMERA_SETUP', 'AUDIT_CASHIER', 'AUDIT_VAULT',
    'AUDIT_COURIER', 'SERVER_ACCESS', 'CASHIER_DAILY_CLOSE', 'VAULT_DAILY_CLOSE'
) ON CONFLICT DO NOTHING;

-- 2.6 irodavezeto (V57 OFFICE_MGR)
INSERT INTO worker_role_permission (role_def_id, permission_id, access_level)
SELECT r.id, p.id, 'FULL' FROM worker_role_def r, permission p
WHERE r.code = 'irodavezeto' AND p.code IN (
    'STATS_VIEW', 'STATS_SUMMARY', 'REPORTS_BANK', 'PRINT_ANY',
    'SERVER_ACCESS', 'TRANSACTION_VIEW_ONLY', 'VAULT_VIEW_ONLY', 'PROFIT_VIEW'
) ON CONFLICT DO NOTHING;

-- 2.7 belso_ellenor (V57 AUDITOR)
INSERT INTO worker_role_permission (role_def_id, permission_id, access_level)
SELECT r.id, p.id, 'FULL' FROM worker_role_def r, permission p
WHERE r.code = 'belso_ellenor' AND p.code IN (
    'TRANSACTION_VIEW_ONLY', 'VAULT_VIEW_ONLY', 'STATS_VIEW',
    'STATS_SUMMARY', 'REPORTS_BANK', 'PRINT_TRIAL', 'AUDIT_CASHIER',
    'AUDIT_VAULT', 'AUDIT_COURIER', 'SERVER_ACCESS', 'PROFIT_VIEW'
) ON CONFLICT DO NOTHING;

-- 2.8 biztonsagi_vezeto (V57 SECURITY)
INSERT INTO worker_role_permission (role_def_id, permission_id, access_level)
SELECT r.id, p.id, 'FULL' FROM worker_role_def r, permission p
WHERE r.code = 'biztonsagi_vezeto' AND p.code IN (
    'CAMERA_VIEW', 'CAMERA_DOWNLOAD', 'CAMERA_SETUP', 'AUDIT_COURIER'
) ON CONFLICT DO NOTHING;

-- 2.9 ugyvezeto (V57 DIRECTOR - mindenhez)
INSERT INTO worker_role_permission (role_def_id, permission_id, access_level)
SELECT r.id, p.id, 'FULL' FROM worker_role_def r, permission p
WHERE r.code = 'ugyvezeto'
ON CONFLICT DO NOTHING;

-- 2.10 irodai_dolgozo + tobbiek: READ-only
INSERT INTO worker_role_permission (role_def_id, permission_id, access_level)
SELECT r.id, p.id, 'READ' FROM worker_role_def r, permission p
WHERE r.code IN ('irodai_dolgozo', 'berszamfejto', 'csoportvezeto', 'penzugyi_vezeto', 'arfolyam_nezo')
  AND p.code IN ('STATS_VIEW', 'TRANSACTION_VIEW_ONLY', 'SERVER_ACCESS')
ON CONFLICT DO NOTHING;
