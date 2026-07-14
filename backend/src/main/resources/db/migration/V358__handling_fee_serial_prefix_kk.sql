-- FKH-018: a KK prefix a kezelési költség önálló bizonylatsorozata.

ALTER TABLE transfer_serial_sequence
    DROP CONSTRAINT IF EXISTS ck_transfer_serial_sequence_prefix;
ALTER TABLE transfer_serial_sequence
    ADD CONSTRAINT ck_transfer_serial_sequence_prefix
        CHECK (prefix IN ('AT', 'AV', 'FF', 'UF', 'KK'));

ALTER TABLE shipment_request
    DROP CONSTRAINT IF EXISTS ck_shipment_request_serial_prefix;
ALTER TABLE shipment_request
    ADD CONSTRAINT ck_shipment_request_serial_prefix
        CHECK (serial_prefix IS NULL OR serial_prefix IN ('AT', 'AV', 'FF', 'UF', 'KK'));
