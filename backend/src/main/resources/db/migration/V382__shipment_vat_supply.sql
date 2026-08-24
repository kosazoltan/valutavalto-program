-- FKH-040: ÁFA átadás-átvétel napló + folyamatos ÁFA-HUF készlet (értéktár-területenként).
-- Elnevezés szándékosan NEM vat_refund* (FR-10) — az ügyfél Tax Free visszatérítéstől elkülönül.
-- vault_territory_id: Integer, Branch.vaultTerritoryId / vault_territory.id mintájára (nem UUID).
-- Bizonylat-prefix: AS (ÁFA Supply) — AV már shipment-átvétel / vat_refund voucher, tilos.

ALTER TABLE transfer_serial_sequence
    DROP CONSTRAINT IF EXISTS ck_transfer_serial_sequence_prefix;
ALTER TABLE transfer_serial_sequence
    ADD CONSTRAINT ck_transfer_serial_sequence_prefix
        CHECK (prefix IN ('AT', 'AV', 'FF', 'UF', 'KK', 'AS'));

ALTER TABLE shipment_request
    DROP CONSTRAINT IF EXISTS ck_shipment_request_serial_prefix;
ALTER TABLE shipment_request
    ADD CONSTRAINT ck_shipment_request_serial_prefix
        CHECK (serial_prefix IS NULL OR serial_prefix IN ('AT', 'AV', 'FF', 'UF', 'KK', 'AS'));

CREATE TABLE IF NOT EXISTS vat_supply_stock (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    company_id UUID NOT NULL,
    vault_territory_id INTEGER NOT NULL,
    current_balance NUMERIC(18,2) NOT NULL DEFAULT 0,
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_vss_balance_nonnegative CHECK (current_balance >= 0),
    CONSTRAINT ux_vss_company_territory UNIQUE (company_id, vault_territory_id)
);

CREATE INDEX IF NOT EXISTS ix_vss_company
    ON vat_supply_stock (company_id);

CREATE TABLE IF NOT EXISTS shipment_vat_supply_item (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    company_id UUID NOT NULL,
    shipment_request_id UUID NOT NULL REFERENCES shipment_request(id),
    from_branch_id UUID NOT NULL,
    to_branch_id UUID NOT NULL,
    huf_amount NUMERIC(18,2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    stock_applied BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    approved_at TIMESTAMP,
    CONSTRAINT chk_svsi_huf_amount_positive CHECK (huf_amount > 0),
    CONSTRAINT ux_svsi_shipment_request UNIQUE (shipment_request_id)
);

CREATE INDEX IF NOT EXISTS ix_svsi_company_status
    ON shipment_vat_supply_item (company_id, status);
CREATE INDEX IF NOT EXISTS ix_svsi_company_approved_at
    ON shipment_vat_supply_item (company_id, approved_at);
