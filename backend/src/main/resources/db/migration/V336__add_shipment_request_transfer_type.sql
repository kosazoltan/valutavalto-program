-- FR-1 (Értéktár Shipment készletkönyvelés): a könyvelési logika tudja, melyik
-- készlet-típust kell mozgatni az átadó/átvevő oldalon.
-- Értékek: VAULT_TO_BRANCH | BRANCH_TO_VAULT | BRANCH_TO_BRANCH | VAULT_TO_VAULT
-- A service szerveroldalon, a Branch.is_vault flag-ekből DERIVÁLJA és tölti ki minden új
-- rögzítésnél (kliens nem hamisíthatja, EZÉRT NINCS @NotNull a DTO-n — a @Valid a controllerben
-- a service-deriválás ELŐTT futna, és minden create-et 400-ra buktatna). A meglévő (régi) sorok
-- NULL-ban maradnak (nullable, backward-compat).
ALTER TABLE shipment_request
  ADD COLUMN IF NOT EXISTS transfer_type VARCHAR(20);

COMMENT ON COLUMN shipment_request.transfer_type IS 'VAULT_TO_BRANCH | BRANCH_TO_VAULT | BRANCH_TO_BRANCH | VAULT_TO_VAULT — szerveroldalon a Branch.is_vault flag-ekből derivált irány a készletkönyveléshez';
