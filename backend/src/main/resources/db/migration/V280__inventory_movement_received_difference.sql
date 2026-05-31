-- V280 — Audit-finding 2026-05-31 (P1): a receiveMovement-nél a ténylegesen fogadott összeg
-- (receivedAmount) eltérhet a mozgás amount-jától, és a különbség eddig NYOM NÉLKÜL eltűnt
-- (nincs difference-rekord, nincs audit) → sérült a "készlet = SUM(tx)" invariáns iroda-/bank
-- szinten. A Transfer alrendszer (transfer.received_amount + transfer.difference) már rögzíti
-- ezt; az inventory_movement-re ugyanezt visszük be.
--
-- Mindkét oszlop NULLABLE (a régi rekordoknál nincs érték; a fogadáskor töltődik). Determinisztikus
-- pénzügyi pontosság: NUMERIC(18,4), mint az amount.

ALTER TABLE inventory_movement
    ADD COLUMN IF NOT EXISTS received_amount NUMERIC(18, 4);

ALTER TABLE inventory_movement
    ADD COLUMN IF NOT EXISTS difference NUMERIC(18, 4);

COMMENT ON COLUMN inventory_movement.received_amount IS
    'A ténylegesen fogadott összeg (receiveMovement). NULL, amíg nincs fogadva.';
COMMENT ON COLUMN inventory_movement.difference IS
    'received_amount - amount (eltérés/hiány a fogadáskor). NULL, amíg nincs fogadva; 0, ha pontos.';
