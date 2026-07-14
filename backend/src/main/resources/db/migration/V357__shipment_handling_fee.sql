-- FKH-018: kezelési költség átvétel az Átadás-átvétel (Shipment) folyamatban.
-- Önálló nyilvántartó tábla (TBD-1 (b) döntés) — a ShipmentRequestItem NEM bővül enum-mal.
-- Tenant-minta: company_id NOT NULL + app-szintű companyId-szűrés (V350–V356 precedens,
-- FK a company-ra szándékosan NINCS). FK a shipment_request-re: a szülő üzletileg nem törlődik.
CREATE TABLE IF NOT EXISTS shipment_handling_fee (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    company_id UUID NOT NULL,
    shipment_request_id UUID NOT NULL REFERENCES shipment_request(id),
    source_branch_id UUID NOT NULL,
    huf_amount NUMERIC(18,2) NOT NULL,
    calculated_fee NUMERIC(18,2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    approved_at TIMESTAMP,
    CONSTRAINT chk_shf_huf_amount_positive CHECK (huf_amount > 0),
    CONSTRAINT chk_shf_fee_nonnegative CHECK (calculated_fee >= 0)
);

-- Duplikált beküldés elleni gát: shipmentenként legfeljebb EGY kezelési költség sor.
CREATE UNIQUE INDEX IF NOT EXISTS ux_shf_shipment_request
    ON shipment_handling_fee (shipment_request_id);
CREATE INDEX IF NOT EXISTS ix_shf_company_status
    ON shipment_handling_fee (company_id, status);
CREATE INDEX IF NOT EXISTS ix_shf_company_approved_at
    ON shipment_handling_fee (company_id, approved_at);
