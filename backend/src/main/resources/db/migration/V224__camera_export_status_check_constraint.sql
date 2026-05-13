-- V224: Copilot P3 #578 follow-up — explicit CHECK constraint a status oszlopon
--
-- Háttér: a V223 a status oszlopot VARCHAR(20)→VARCHAR(30)-ra szélesítette, hogy a
-- AWAITING_SECOND_APPROVAL (24 karakter) elférjen. Copilot felvetette: a hossz-alapú
-- védelem törékeny, mert egy jövőbeni hosszabb enum érték (pl. 31+ chars) ismét
-- silent value-too-long crash-be futna.
--
-- Megoldás: explicit CHECK constraint, amely felsorolja az ÖSSZES megengedett értéket.
-- Új enum érték → migration kötelező → schema-szinten elkapja a hiányosságot,
-- NEM production-crash-tel.

ALTER TABLE camera_export_request
    DROP CONSTRAINT IF EXISTS chk_camera_export_status;

ALTER TABLE camera_export_request
    ADD CONSTRAINT chk_camera_export_status
    CHECK (status IN (
        'REQUESTED',
        'AWAITING_SECOND_APPROVAL',
        'APPROVED',
        'REJECTED',
        'EXPORTING',
        'COMPLETED',
        'FAILED'
    ));
