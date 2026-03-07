-- ============================================================
-- V57: Szerepkör (Role) jogosultsági rendszer
-- Worker domain-specific operational roles + permissions
-- Backward compatible: worker.role enum mező MARAD
-- ============================================================

-- 1. Ensure base permission table exists (matching Permission.java entity)
CREATE TABLE IF NOT EXISTS permission (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    module VARCHAR(50) NOT NULL DEFAULT 'GENERAL',
    is_system_permission BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Ensure base role table exists (matching Role.java entity)
CREATE TABLE IF NOT EXISTS role (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    role_type VARCHAR(30),
    hierarchy_level INT,
    is_system_role BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. Ensure role_permission join table exists (Role ↔ Permission)
CREATE TABLE IF NOT EXISTS role_permission (
    role_id UUID NOT NULL REFERENCES role(id),
    permission_id UUID NOT NULL REFERENCES permission(id),
    PRIMARY KEY(role_id, permission_id)
);

-- ============================================================
-- 4. Operatív szerepkör tábla (9 domain-specifikus role)
-- ============================================================
CREATE TABLE IF NOT EXISTS worker_role_def (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name_hu VARCHAR(100) NOT NULL,
    description_hu VARCHAR(500)
);

-- 5. Worker ↔ Role kapcsolótábla (egy workernek TÖBB szerepe lehet)
CREATE TABLE IF NOT EXISTS worker_role_assignment (
    id BIGSERIAL PRIMARY KEY,
    worker_id BIGINT NOT NULL REFERENCES worker(id),
    role_def_id INT NOT NULL REFERENCES worker_role_def(id),
    is_primary BOOLEAN DEFAULT false,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(worker_id, role_def_id)
);

CREATE INDEX IF NOT EXISTS idx_wra_worker ON worker_role_assignment(worker_id);
CREATE INDEX IF NOT EXISTS idx_wra_role ON worker_role_assignment(role_def_id);

-- 6. WorkerRoleDef ↔ Permission kapcsolótábla
CREATE TABLE IF NOT EXISTS worker_role_permission (
    role_def_id INT NOT NULL REFERENCES worker_role_def(id),
    permission_id UUID NOT NULL REFERENCES permission(id),
    access_level VARCHAR(20) DEFAULT 'FULL',
    PRIMARY KEY(role_def_id, permission_id)
);

-- ============================================================
-- Seed: 9 operatív szerepkör
-- ============================================================
INSERT INTO worker_role_def (code, name_hu, description_hu) VALUES
('CASHIER', 'Valutapénztáros', 'Valutaváltási tranzakciókat végez, ügyfélkiszolgálás'),
('COURIER', 'Értékszállító', 'Pénz szállítás irodák/bank között, átadás-átvétel elismerés'),
('VAULT_KEEPER', 'Értéktáros', 'Értéktár kezelés, belső mozgások, statisztikák, egyedi árfolyam'),
('CHIEF_VAULT', 'Főértéktáros', 'Árfolyamkészítés, teljes áttekintés, banki riportok, szerverhozzáférés'),
('REGIONAL_MGR', 'Területi vezető', 'Teljes ellenőrzés, kamerák, rovancsolás, PIN beállítás'),
('OFFICE_MGR', 'Irodavezető', 'Statisztikák, adatok hozzáférés (árfolyam nélkül)'),
('AUDITOR', 'Kontroller', 'Belső ellenőrzés, próbanyomtatás, számviteli audit'),
('SECURITY', 'Biztonsági vezető', 'Kamera beállítás/letöltés, értékszállító ellenőrzés'),
('DIRECTOR', 'Igazgató', 'Teljes hozzáférés mindenhez')
ON CONFLICT (code) DO NOTHING;

-- ============================================================
-- Seed: Jogosultságok (28 darab) — INSERT into existing permission table
-- ============================================================
INSERT INTO permission (id, code, name, description, module, is_system_permission, is_active) VALUES
(gen_random_uuid(), 'TRANSACTION_BUY', 'Valuta vétel ügyféltől', 'Valuta vétel ügyféltől', 'TRANSACTION', true, true),
(gen_random_uuid(), 'TRANSACTION_SELL', 'Valuta eladás ügyfélnek', 'Valuta eladás ügyfélnek', 'TRANSACTION', true, true),
(gen_random_uuid(), 'TRANSACTION_WU', 'Western Union/Moneygram', 'Western Union/Moneygram kezelés', 'TRANSACTION', true, true),
(gen_random_uuid(), 'TRANSACTION_VAT_REFUND', 'ÁFA visszatérítés', 'ÁFA visszatérítés végrehajtás', 'TRANSACTION', true, true),
(gen_random_uuid(), 'TRANSFER_ACKNOWLEDGE', 'Átadás-átvétel elismerés', 'Átadás-átvétel elismerés', 'TRANSFER', true, true),
(gen_random_uuid(), 'TRANSFER_COURIER_PIN', 'Értékszállító PIN kezelés', 'Értékszállító PIN kezelés', 'TRANSFER', true, true),
(gen_random_uuid(), 'VAULT_RECEIVE', 'Értéktár: átvétel', 'Értéktár: átvétel (bank/pénztár/másik)', 'VAULT', true, true),
(gen_random_uuid(), 'VAULT_SEND', 'Értéktár: átadás', 'Értéktár: átadás (bank/pénztár/másik)', 'VAULT', true, true),
(gen_random_uuid(), 'VAULT_DAILY_CLOSE', 'Értéktári napi zárás', 'Értéktári napi zárás végrehajtás', 'VAULT', true, true),
(gen_random_uuid(), 'CASHIER_DAILY_CLOSE', 'Pénztári napi zárás', 'Pénztári napi zárás végrehajtás', 'CLOSING', true, true),
(gen_random_uuid(), 'RATE_CREATE', 'Árfolyam készítés', 'Árfolyam készítés és módosítás', 'RATE', true, true),
(gen_random_uuid(), 'RATE_CUSTOM', 'Egyedi árfolyam', 'Egyedi árfolyam (jelszavas)', 'RATE', true, true),
(gen_random_uuid(), 'STATS_VIEW', 'Statisztikák megtekintés', 'Statisztikák megtekintés', 'REPORTS', true, true),
(gen_random_uuid(), 'STATS_SUMMARY', 'Összesítők készítés', 'Összesítők készítés', 'REPORTS', true, true),
(gen_random_uuid(), 'REPORTS_BANK', 'Banki riportok', 'Banki riportok generálás', 'REPORTS', true, true),
(gen_random_uuid(), 'PROFIT_VIEW', 'Haszonszámítás megtekintés', 'Haszonszámítás megtekintés (WAC)', 'REPORTS', true, true),
(gen_random_uuid(), 'PRINT_ANY', 'Nyomtatás (bármit)', 'Nyomtatás bármilyen dokumentumot', 'PRINT', true, true),
(gen_random_uuid(), 'PRINT_TRIAL', 'Próbanyomtatás', 'Próbanyomtatás végrehajtás', 'PRINT', true, true),
(gen_random_uuid(), 'CAMERA_VIEW', 'Kamera megtekintés', 'Kamera megtekintés', 'CAMERA', true, true),
(gen_random_uuid(), 'CAMERA_DOWNLOAD', 'Kamera felvétel letöltés', 'Kamera felvétel letöltés', 'CAMERA', true, true),
(gen_random_uuid(), 'CAMERA_SETUP', 'Kamera beállítás', 'Kamera beállítás', 'CAMERA', true, true),
(gen_random_uuid(), 'AUDIT_CASHIER', 'Pénztár rovancsolás', 'Pénztár rovancsolás', 'AUDIT', true, true),
(gen_random_uuid(), 'AUDIT_VAULT', 'Értéktár rovancsolás', 'Értéktár rovancsolás', 'AUDIT', true, true),
(gen_random_uuid(), 'AUDIT_COURIER', 'Értékszállító ellenőrzés', 'Értékszállító ellenőrzés', 'AUDIT', true, true),
(gen_random_uuid(), 'SERVER_ACCESS', 'Szerver adatok letöltés', 'Szerver adatok letöltés/összesítés', 'ADMIN', true, true),
(gen_random_uuid(), 'WORKER_MANAGE', 'Dolgozó kezelés', 'Dolgozó kezelés', 'ADMIN', true, true),
(gen_random_uuid(), 'TRANSACTION_VIEW_ONLY', 'Tranzakciók megtekintés', 'Tranzakciók megtekintés (csak olvasás)', 'TRANSACTION', true, true),
(gen_random_uuid(), 'VAULT_VIEW_ONLY', 'Értéktár megtekintés', 'Értéktár megtekintés (csak olvasás)', 'VAULT', true, true)
ON CONFLICT (code) DO NOTHING;

-- ============================================================
-- Role ↔ Permission hozzárendelések
-- ============================================================

-- CASHIER
INSERT INTO worker_role_permission (role_def_id, permission_id, access_level)
SELECT r.id, p.id, 'FULL' FROM worker_role_def r, permission p
WHERE r.code = 'CASHIER' AND p.code IN (
    'TRANSACTION_BUY', 'TRANSACTION_SELL', 'TRANSACTION_WU',
    'TRANSACTION_VAT_REFUND', 'TRANSFER_ACKNOWLEDGE',
    'CASHIER_DAILY_CLOSE', 'PRINT_ANY'
)
ON CONFLICT DO NOTHING;

-- COURIER
INSERT INTO worker_role_permission (role_def_id, permission_id, access_level)
SELECT r.id, p.id, 'FULL' FROM worker_role_def r, permission p
WHERE r.code = 'COURIER' AND p.code IN ('TRANSFER_ACKNOWLEDGE')
ON CONFLICT DO NOTHING;

-- VAULT_KEEPER
INSERT INTO worker_role_permission (role_def_id, permission_id, access_level)
SELECT r.id, p.id, 'FULL' FROM worker_role_def r, permission p
WHERE r.code = 'VAULT_KEEPER' AND p.code IN (
    'VAULT_RECEIVE', 'VAULT_SEND', 'VAULT_DAILY_CLOSE',
    'TRANSFER_ACKNOWLEDGE', 'RATE_CUSTOM', 'STATS_VIEW',
    'STATS_SUMMARY', 'PRINT_ANY', 'PROFIT_VIEW', 'TRANSACTION_VIEW_ONLY'
)
ON CONFLICT DO NOTHING;

-- CHIEF_VAULT
INSERT INTO worker_role_permission (role_def_id, permission_id, access_level)
SELECT r.id, p.id, 'FULL' FROM worker_role_def r, permission p
WHERE r.code = 'CHIEF_VAULT' AND p.code IN (
    'VAULT_RECEIVE', 'VAULT_SEND', 'VAULT_DAILY_CLOSE',
    'TRANSFER_ACKNOWLEDGE', 'RATE_CREATE', 'RATE_CUSTOM',
    'STATS_VIEW', 'STATS_SUMMARY', 'REPORTS_BANK', 'PROFIT_VIEW',
    'PRINT_ANY', 'SERVER_ACCESS', 'TRANSACTION_VIEW_ONLY', 'CASHIER_DAILY_CLOSE'
)
ON CONFLICT DO NOTHING;

-- REGIONAL_MGR
INSERT INTO worker_role_permission (role_def_id, permission_id, access_level)
SELECT r.id, p.id, 'FULL' FROM worker_role_def r, permission p
WHERE r.code = 'REGIONAL_MGR' AND p.code IN (
    'TRANSACTION_VIEW_ONLY', 'VAULT_VIEW_ONLY', 'TRANSFER_ACKNOWLEDGE',
    'TRANSFER_COURIER_PIN', 'RATE_CUSTOM', 'STATS_VIEW', 'STATS_SUMMARY',
    'REPORTS_BANK', 'PROFIT_VIEW', 'PRINT_ANY', 'CAMERA_VIEW',
    'CAMERA_DOWNLOAD', 'CAMERA_SETUP', 'AUDIT_CASHIER', 'AUDIT_VAULT',
    'AUDIT_COURIER', 'SERVER_ACCESS', 'CASHIER_DAILY_CLOSE', 'VAULT_DAILY_CLOSE'
)
ON CONFLICT DO NOTHING;

-- OFFICE_MGR
INSERT INTO worker_role_permission (role_def_id, permission_id, access_level)
SELECT r.id, p.id, 'FULL' FROM worker_role_def r, permission p
WHERE r.code = 'OFFICE_MGR' AND p.code IN (
    'STATS_VIEW', 'STATS_SUMMARY', 'REPORTS_BANK', 'PRINT_ANY',
    'SERVER_ACCESS', 'TRANSACTION_VIEW_ONLY', 'VAULT_VIEW_ONLY', 'PROFIT_VIEW'
)
ON CONFLICT DO NOTHING;

-- AUDITOR
INSERT INTO worker_role_permission (role_def_id, permission_id, access_level)
SELECT r.id, p.id, 'FULL' FROM worker_role_def r, permission p
WHERE r.code = 'AUDITOR' AND p.code IN (
    'TRANSACTION_VIEW_ONLY', 'VAULT_VIEW_ONLY', 'STATS_VIEW',
    'STATS_SUMMARY', 'REPORTS_BANK', 'PRINT_TRIAL', 'AUDIT_CASHIER',
    'AUDIT_VAULT', 'AUDIT_COURIER', 'SERVER_ACCESS', 'PROFIT_VIEW'
)
ON CONFLICT DO NOTHING;

-- SECURITY
INSERT INTO worker_role_permission (role_def_id, permission_id, access_level)
SELECT r.id, p.id, 'FULL' FROM worker_role_def r, permission p
WHERE r.code = 'SECURITY' AND p.code IN (
    'CAMERA_VIEW', 'CAMERA_DOWNLOAD', 'CAMERA_SETUP', 'AUDIT_COURIER'
)
ON CONFLICT DO NOTHING;

-- DIRECTOR (mindenhez hozzáfér)
INSERT INTO worker_role_permission (role_def_id, permission_id)
SELECT r.id, p.id FROM worker_role_def r, permission p
WHERE r.code = 'DIRECTOR'
ON CONFLICT DO NOTHING;
