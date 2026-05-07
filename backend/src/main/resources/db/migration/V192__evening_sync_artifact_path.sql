ALTER TABLE evening_sync_log
    ADD COLUMN IF NOT EXISTS artifact_path VARCHAR(1024);

COMMENT ON COLUMN evening_sync_log.artifact_path
    IS 'Managed-storage artifact relatív hivatkozása esti zárás szinkron hibánál vagy artifact-only ágnál';
