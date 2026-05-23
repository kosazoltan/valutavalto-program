-- ============================================================================
-- V258 (G27, legacy Anti/VALUTA BIGCTRL+TEAOR): jogi-személy ügyfél TEÁOR
-- tevékenységi kódja. A legacy "UPDATE JOGI SET TEAOR" mezőjének megfelelője.
-- Additív, nullable.
-- ============================================================================

ALTER TABLE customer
    ADD COLUMN IF NOT EXISTS teaor_code VARCHAR(16);
