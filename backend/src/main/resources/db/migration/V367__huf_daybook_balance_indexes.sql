-- FKH-022 kiegészítés FR-K5: Nyitó/Záró egyenleg — kumulált SUM-lekérdezések indexei.
--
-- A Nyitó egyenleg a nap ELŐTTI összes FF/UF tétel előjeles összege (implicit horgony),
-- ami range-szűrést futtat:
--   shipment_request: company_id = ? AND serial_prefix IN ('FF','UF') AND request_date < ?
--   transfer:         company_id = ? AND transfer_date < ?
--
-- Kiinduló állapot (RED-köri index-audit, 2026-07-29):
--   - shipment_request.request_date-re SEMMILYEN index nem volt (a napi lista-lekérdezés
--     is enélkül futott); meglévők: (serial_prefix, serial_number) V304,
--     (company_id, request_number) partial unique V304, (to_branch_id, status) V359.
--   - transfer: csak egyoszlopos idx_transfer_date (V63), company_id-re nincs index.
--
-- A FF-%%/UF-%% transferNumber LIKE-minta btree-vel nem horgonyozható jól — a
-- (company_id, transfer_date) + a meglévő from/to_branch indexek elegendők.
-- A cancelled_at-alapú sztornó-ág indexelése tudatosan kihagyva (opcionális follow-up,
-- ha a volumen nő) — a driver-szűrő ott is a company_id.

CREATE INDEX IF NOT EXISTS idx_shipment_request_company_prefix_date
    ON shipment_request (company_id, serial_prefix, request_date);

CREATE INDEX IF NOT EXISTS idx_transfer_company_date
    ON transfer (company_id, transfer_date);
