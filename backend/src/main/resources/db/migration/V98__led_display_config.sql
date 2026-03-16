-- V98: LED kijelző soros port konfiguráció bővítés
-- Az existing led_display_config táblát bővíti a serial COM port mezőkkel
-- Legacy: Delphi LED vezérlés teljes átültetése (15+ variáns konszolidálva)

ALTER TABLE led_display_config
    ADD COLUMN IF NOT EXISTS serial_display_type VARCHAR(30) DEFAULT 'STANDARD',
    ADD COLUMN IF NOT EXISTS com_ports            VARCHAR(100) DEFAULT 'COM1',
    ADD COLUMN IF NOT EXISTS currencies           VARCHAR(200) DEFAULT 'EUR,USD,GBP,CHF',
    ADD COLUMN IF NOT EXISTS show_bank_card       BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS speed_command        BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN IF NOT EXISTS speed                INTEGER NOT NULL DEFAULT 5,
    ADD COLUMN IF NOT EXISTS end_markers          VARCHAR(20)  DEFAULT '254',
    ADD COLUMN IF NOT EXISTS decimal_separator    CHAR(1)      DEFAULT ',',
    ADD COLUMN IF NOT EXISTS custom_text          TEXT,
    ADD COLUMN IF NOT EXISTS display_ids          VARCHAR(50),
    ADD COLUMN IF NOT EXISTS updated_at           TIMESTAMP;

-- Egyedi index a branch_id-re (ha még nincs UNIQUE constraint)
CREATE UNIQUE INDEX IF NOT EXISTS idx_led_display_branch_unique
    ON led_display_config(branch_id);

COMMENT ON COLUMN led_display_config.serial_display_type IS
    'STANDARD | CENTRAL_EU | EXTENDED | TEXT_ONLY | MIXED | DUAL_SAME | DUAL_DIFF';
COMMENT ON COLUMN led_display_config.com_ports IS
    'Vesszővel elválasztott COM portok, pl. COM1 vagy COM1,COM2';
COMMENT ON COLUMN led_display_config.currencies IS
    'Vesszővel elválasztott valuták, pl. EUR,USD,GBP,CHF';
COMMENT ON COLUMN led_display_config.end_markers IS
    'Bájt értékek vesszővel, pl. 254 vagy 254,255 (0xFE, 0xFF)';
