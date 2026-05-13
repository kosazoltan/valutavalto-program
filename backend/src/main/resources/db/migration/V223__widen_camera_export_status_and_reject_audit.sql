-- V223: Codex P1 #570 backlog fix — camera_export_request fixes
--
-- 1. status VARCHAR(20) → VARCHAR(30):
--    A V220 bevezette az AWAITING_SECOND_APPROVAL enum értéket (24 karakter),
--    de a V108_1 a status oszlopot VARCHAR(20)-nak hozta létre. Az entity length=20
--    is. Production-ban a `approveExport()` AWAITING_SECOND_APPROVAL state-re vált:
--    persistence value-too-long crash. Most VARCHAR(30) a biztonságos rezerva.
--
-- 2. rejected_by + rejected_at külön audit oszlopok (Codex P2 #570 finding 3236362433):
--    A `rejectExport()` jelenleg overwrite-olja az approved_by/approved_at-ot a
--    rejector adataival. Dual-approval flow-ban ez 1. approver audit-loss.
--    Új oszlopok: rejected_by + rejected_at külön mező, approved_by/approved_at
--    megmarad (ha volt 1. approval), reject külön track-elhető.

-- 1. Widen status oszlop
ALTER TABLE camera_export_request
    ALTER COLUMN status TYPE VARCHAR(30);

-- 2. Új rejected_by + rejected_at oszlopok (null-able, mert csak rejected request-eknek van)
ALTER TABLE camera_export_request
    ADD COLUMN IF NOT EXISTS rejected_by  VARCHAR(100),
    ADD COLUMN IF NOT EXISTS rejected_at  TIMESTAMP WITHOUT TIME ZONE;
