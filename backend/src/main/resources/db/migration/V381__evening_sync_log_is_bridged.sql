-- FK-091: evening_sync_log.is_bridged — HQ vészkijárat (helyi artifact) vs valódi HQ 2xx.
-- Zero-downtime: NOT NULL + DEFAULT false, nincs backfill, nincs kétfázisú deploy.

ALTER TABLE evening_sync_log ADD COLUMN is_bridged BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN evening_sync_log.is_bridged IS 'true, ha a sor a HQ-kuldes veszkijaratan (helyi fajlba iras) keresztul lett sikeresnek jelolve, nem valodi HQ-valasz alapjan.';
