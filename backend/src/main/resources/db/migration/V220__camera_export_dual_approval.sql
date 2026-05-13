-- V220: Hatósági kamera-export 4-eyes (dual approval) (Sprint 4 — P2-C)
-- A meglévő CameraExportRequest 1-jóváhagyós volt, most opcionálisan 2-jóváhagyóst tesz lehetővé.
-- A `requires_dual_approval = true` default (a v2.0 spec és Anti masterplan §12.4 szerint).

ALTER TABLE camera_export_request
    ADD COLUMN IF NOT EXISTS requires_dual_approval BOOLEAN NOT NULL DEFAULT true;

ALTER TABLE camera_export_request
    ADD COLUMN IF NOT EXISTS second_approved_by VARCHAR(100);

ALTER TABLE camera_export_request
    ADD COLUMN IF NOT EXISTS second_approved_at TIMESTAMP;

-- A status enum-ba új érték (AWAITING_SECOND_APPROVAL) bekerült a Java enum-ban,
-- DB szinten VARCHAR(20), nincs CHECK constraint, nem kell migration.
