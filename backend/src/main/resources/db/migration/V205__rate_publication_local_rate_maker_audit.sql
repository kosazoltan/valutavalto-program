-- V205: Helyi foertektar arfolyamkeszito kliens audit mezoi.
--
-- Architektura dontes (2026-05-12):
-- - Az arfolyamot nem a szerveren szerkesztjuk.
-- - A foertektaros kulon, helyileg telepitett arfolyamkeszito alkalmazasban
--   kesziti el az arfolyamcsomagot.
-- - A szerver hitelesitett atvevo, validator, audit trail es teritesi kozpont.
-- - A penztarak tovabbra is automatikusan a szerverrol olvassak be az aktualis
--   exchange_rate rekordokat.

ALTER TABLE rate_publication
    ADD COLUMN IF NOT EXISTS source VARCHAR(32) NOT NULL DEFAULT 'SERVER_UI',
    ADD COLUMN IF NOT EXISTS client_package_id VARCHAR(80),
    ADD COLUMN IF NOT EXISTS client_package_hash VARCHAR(128),
    ADD COLUMN IF NOT EXISTS client_version VARCHAR(40),
    ADD COLUMN IF NOT EXISTS client_device_id VARCHAR(80);

CREATE UNIQUE INDEX IF NOT EXISTS ux_rate_publication_company_client_package
    ON rate_publication (company_id, client_package_id)
    WHERE client_package_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_rate_publication_source_published
    ON rate_publication (source, published_at DESC);
