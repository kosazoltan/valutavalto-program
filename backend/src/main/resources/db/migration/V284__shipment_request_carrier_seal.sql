-- V284: Átadás-átvétel (szállítmány-igény) szállító + plombaszám mezők (FK02, FR-1..5).
-- A ShipmentNewPage (Értéktári Átadás-átvétel) most kötelezően rögzíti a szállító nevét és a
-- plombaszámot. Az oszlopok nullable-ként adódnak hozzá (zero-downtime: a meglévő rekordok nem
-- törnek); az új-rekord-kötelezőséget a ShipmentRequest entity @NotBlank/@Pattern Bean Validationje
-- adja a create/update endpointon. A plombaszám-formátumot NULL-megengedő CHECK védi.

ALTER TABLE shipment_request ADD COLUMN IF NOT EXISTS carrier_name VARCHAR(128);
ALTER TABLE shipment_request ADD COLUMN IF NOT EXISTS seal_number  VARCHAR(64);

-- Legacy-backfill (P1): a V284 ELŐTT létrejött rekordok carrier/seal-je NULL. A @NotBlank a
-- Hibernate PRE_UPDATE eseménynél is lefut (validation.mode=AUTO + hibernate-validator a
-- classpath-on), így egy régi rekord BÁRMELY státuszváltása (submit/approve/deliver/cancel/reject)
-- ConstraintViolation → HTTP 500 lenne. A meglévő NULL sorokat placeholder-rel töltjük fel, hogy a
-- status-transition save-ek ne bukjanak. Az új rekordokat továbbra is a @Valid kényszeríti.
-- A 'LEGACY' megfelel a plomba CHECK-formátumnak (^[A-Za-z0-9/-]+$).
UPDATE shipment_request SET carrier_name = 'ISMERETLEN' WHERE carrier_name IS NULL OR btrim(carrier_name) = '';
UPDATE shipment_request SET seal_number  = 'LEGACY'     WHERE seal_number  IS NULL OR btrim(seal_number)  = '';

ALTER TABLE shipment_request DROP CONSTRAINT IF EXISTS chk_shipment_request_seal_number_format;
ALTER TABLE shipment_request
    ADD CONSTRAINT chk_shipment_request_seal_number_format
    CHECK (seal_number IS NULL OR seal_number ~ '^[A-Za-z0-9/-]+$');
