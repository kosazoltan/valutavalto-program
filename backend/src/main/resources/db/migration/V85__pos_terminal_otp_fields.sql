-- =============================================================================
-- V85: POS terminál OTP protokoll mezők
-- Legacy: HARDWARE.POSHOST, HARDWARE.POSPORT
-- =============================================================================

ALTER TABLE pos_terminal
    ADD COLUMN IF NOT EXISTS ip_address VARCHAR(50),
    ADD COLUMN IF NOT EXISTS port INTEGER;

COMMENT ON COLUMN pos_terminal.ip_address IS 'Terminál IP cím (Legacy: HARDWARE.POSHOST)';
COMMENT ON COLUMN pos_terminal.port IS 'Terminál port (Legacy: HARDWARE.POSPORT)';
