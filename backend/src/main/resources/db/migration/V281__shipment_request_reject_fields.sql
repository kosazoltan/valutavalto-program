-- V281 — F3 (2026-06-01): dedikált szállítmány-ELUTASÍTÁS (reject) audit-mezői.
--
-- Az elutasítás (reject) és a visszavonás (cancel) eddig ugyanazt a /cancel utat használta,
-- ami auditálási és üzleti szempontból helytelen (két külön folyamat). A dedikált reject
-- a status-t REJECTED-re állítja, és rögzíti az indokot + az elutasító dolgozót.
--
-- A status oszlop @Enumerated(STRING) VARCHAR(20), nincs DB CHECK constraint az értékeken,
-- ezért a REJECTED enum-érték önmagában NEM igényel séma-módosítást — csak a két új audit-oszlop.
-- Mindkét oszlop NULLABLE (a régi rekordoknál nincs érték; elutasításkor töltődik).

ALTER TABLE shipment_request
    ADD COLUMN IF NOT EXISTS rejection_reason TEXT,
    ADD COLUMN IF NOT EXISTS rejected_by_worker_id BIGINT;
