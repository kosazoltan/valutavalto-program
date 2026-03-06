-- V43: POS terminál konfiguráció és fizetési mód bővítés
-- Legacy: OTP terminál integráció (OtpTermStorno, OtpAruvisszavet, otpterminal DLL-ek)
-- Modern: többféle terminál típus támogatása (OTP, Borgun, Worldline, MOCK)

-- ============================================================
-- 1. POS_TERMINAL tábla bővítése — terminál típus és JSON konfiguráció
-- ============================================================
ALTER TABLE pos_terminal ADD COLUMN IF NOT EXISTS terminal_type VARCHAR(30) DEFAULT 'MOCK';
ALTER TABLE pos_terminal ADD COLUMN IF NOT EXISTS config_json TEXT;

COMMENT ON COLUMN pos_terminal.terminal_type IS 'Terminál típus: MOCK, OTP, BORGUN, WORLDLINE';
COMMENT ON COLUMN pos_terminal.config_json IS 'Terminál-specifikus konfiguráció JSON formátumban (IP, port, protocol stb.)';

-- ============================================================
-- 2. TRANSACTION tábla bővítés — fizetési mód (CASH/CARD)
-- ============================================================
ALTER TABLE transaction ADD COLUMN IF NOT EXISTS payment_method VARCHAR(20) DEFAULT 'CASH';
ALTER TABLE transaction ADD COLUMN IF NOT EXISTS pos_authorization_code VARCHAR(50);
ALTER TABLE transaction ADD COLUMN IF NOT EXISTS pos_reference_number VARCHAR(100);
ALTER TABLE transaction ADD COLUMN IF NOT EXISTS pos_terminal_id VARCHAR(50);

COMMENT ON COLUMN transaction.payment_method IS 'Fizetési mód: CASH (készpénz), CARD (bankkártya)';
COMMENT ON COLUMN transaction.pos_authorization_code IS 'POS terminál autorizációs kód (kártyás fizetésnél)';
COMMENT ON COLUMN transaction.pos_reference_number IS 'POS terminál referencia szám';
COMMENT ON COLUMN transaction.pos_terminal_id IS 'POS terminál azonosító (melyik terminálon történt)';

-- ============================================================
-- 3. POS terminal mode rendszerparaméter
-- ============================================================
INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active, created_at)
VALUES (
    gen_random_uuid(),
    'pos.terminal.mode',
    'mock',
    'STRING',
    'POS',
    'POS terminál mód: mock (szimuláció), otp (OTP Bank), borgun (Borgun), worldline (Worldline)',
    true,
    NOW()
) ON CONFLICT (parameter_key) DO NOTHING;

INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active, created_at)
VALUES (
    gen_random_uuid(),
    'pos.terminal.timeout.seconds',
    '30',
    'INTEGER',
    'POS',
    'POS terminál tranzakció timeout másodpercben',
    true,
    NOW()
) ON CONFLICT (parameter_key) DO NOTHING;

INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active, created_at)
VALUES (
    gen_random_uuid(),
    'evening.closing.headquarters.url',
    '',
    'STRING',
    'SYNC',
    'Központi szerver URL esti zárás adatcsomag küldéséhez (REST API)',
    true,
    NOW()
) ON CONFLICT (parameter_key) DO NOTHING;

-- ============================================================
-- 4. Evening sync státusz tábla
-- ============================================================
CREATE TABLE IF NOT EXISTS evening_sync_log (
    id              BIGSERIAL PRIMARY KEY,
    branch_id       UUID NOT NULL,
    sync_date       DATE NOT NULL,
    status          VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    package_checksum VARCHAR(128),
    attempt_count   INTEGER NOT NULL DEFAULT 0,
    last_attempt_at TIMESTAMP,
    completed_at    TIMESTAMP,
    error_message   TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_evening_sync_branch FOREIGN KEY (branch_id) REFERENCES branch(id)
);

CREATE INDEX IF NOT EXISTS idx_evening_sync_branch_date ON evening_sync_log(branch_id, sync_date);

COMMENT ON TABLE evening_sync_log IS 'Esti zárás szinkronizáció napló (legacy: FTP-n küldött ESTIZAR csomag)';
