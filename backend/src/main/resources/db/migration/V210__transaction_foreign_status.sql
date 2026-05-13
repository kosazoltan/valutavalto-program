-- V207: Devizastatusz mezo (kulfoldi/belfoldi) a tranzakcio tablaban
-- A bizonylatra nyomtatott mező — DOMESTIC vagy FOREIGN
ALTER TABLE transaction ADD COLUMN IF NOT EXISTS foreign_status VARCHAR(10);
