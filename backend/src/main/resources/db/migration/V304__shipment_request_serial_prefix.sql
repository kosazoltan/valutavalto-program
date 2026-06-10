-- Atadas-atvetel bizonylat sorszam bontasa tipus + valuta szerint.
-- A request_number mar az emberi sorszamot hordozza (AT/AV/FF/UF-NNNNNN);
-- ezek a mezok audit- es riportcelra taroljak a prefixet es a monoton szamot.

ALTER TABLE shipment_request ADD COLUMN IF NOT EXISTS serial_prefix VARCHAR(4);
ALTER TABLE shipment_request ADD COLUMN IF NOT EXISTS serial_number BIGINT;
ALTER TABLE shipment_request ADD COLUMN IF NOT EXISTS company_id UUID;

UPDATE shipment_request sr
SET company_id = b.company_id
FROM branch b
WHERE sr.from_branch_id = b.id
  AND sr.company_id IS NULL;

CREATE INDEX IF NOT EXISTS idx_shipment_request_serial_prefix
    ON shipment_request (serial_prefix, serial_number);

ALTER TABLE shipment_request DROP CONSTRAINT IF EXISTS idx_shipment_request_number;
ALTER TABLE shipment_request DROP CONSTRAINT IF EXISTS uk_shipment_request_number;
DROP INDEX IF EXISTS idx_shipment_request_number;
DROP INDEX IF EXISTS uk_shipment_request_number;
CREATE UNIQUE INDEX IF NOT EXISTS idx_shipment_request_company_number
    ON shipment_request (company_id, request_number)
    WHERE company_id IS NOT NULL;

ALTER TABLE shipment_request DROP CONSTRAINT IF EXISTS ck_shipment_request_serial_prefix;
ALTER TABLE shipment_request ADD CONSTRAINT ck_shipment_request_serial_prefix
    CHECK (serial_prefix IS NULL OR serial_prefix IN ('AT', 'AV', 'FF', 'UF'));

ALTER TABLE shipment_request DROP CONSTRAINT IF EXISTS ck_shipment_request_serial_number;
ALTER TABLE shipment_request ADD CONSTRAINT ck_shipment_request_serial_number
    CHECK (serial_number IS NULL OR serial_number > 0);
