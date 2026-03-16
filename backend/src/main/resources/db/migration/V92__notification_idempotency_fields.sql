-- V92: Notification tábla idempotency mezők hozzáadása
-- Szükséges: ReservationService.sendPreExpiryWarnings() idempotens értesítés-kezeléshez

ALTER TABLE notification
    ADD COLUMN IF NOT EXISTS entity_type       VARCHAR(100),
    ADD COLUMN IF NOT EXISTS entity_id         VARCHAR(100),
    ADD COLUMN IF NOT EXISTS notification_type VARCHAR(100);

-- Index az idempotency lekérdezéshez
CREATE INDEX IF NOT EXISTS idx_notification_entity_type_id_ntype
    ON notification (entity_type, entity_id, notification_type)
    WHERE entity_type IS NOT NULL;
