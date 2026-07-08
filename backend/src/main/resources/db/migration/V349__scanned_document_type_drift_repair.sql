-- V349: TD8 V39-TYPE-DRIFT repair — scanned_document.customer_id / transaction_id UUID→BIGINT.
-- Drift: a V39 UUID-ként hozta létre az oszlopokat, az entity (ScannedDocument.java) Long.
-- Prod: a ddl-auto=update korszakban a tábla BIGINT oszlopokkal jött létre → a uuid-feltétel
-- nem teljesül → NO-OP, adat és index érintetlen.
-- Friss Flyway-DB: V39 → uuid; a tábla a migráció-láncban bizonyítottan üres (0 seed
-- INSERT/UPDATE a migrációkban), ezért a USING NULL biztonságos: nincs értelmes
-- UUID→BIGINT konverzió és nincs konvertálandó sor. Fail-closed őr: ha mégis lenne
-- nem-NULL uuid-adat, HANGOSAN elszállunk, nem NULL-ozunk csendben.

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
          FROM pg_attribute
         WHERE attrelid = 'scanned_document'::regclass
           AND attname = 'customer_id'
           AND NOT attisdropped
           AND atttypid = 'uuid'::regtype
    ) THEN
        IF EXISTS (SELECT 1 FROM scanned_document WHERE customer_id IS NOT NULL) THEN
            RAISE EXCEPTION 'V349: scanned_document.customer_id uuid típusú ÉS nem-NULL adatot tartalmaz — kézi vizsgálat kell, csendes NULL-ozás tilos!';
        END IF;
        ALTER TABLE scanned_document
            ALTER COLUMN customer_id TYPE BIGINT USING NULL;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM pg_attribute
         WHERE attrelid = 'scanned_document'::regclass
           AND attname = 'transaction_id'
           AND NOT attisdropped
           AND atttypid = 'uuid'::regtype
    ) THEN
        IF EXISTS (SELECT 1 FROM scanned_document WHERE transaction_id IS NOT NULL) THEN
            RAISE EXCEPTION 'V349: scanned_document.transaction_id uuid típusú ÉS nem-NULL adatot tartalmaz — kézi vizsgálat kell, csendes NULL-ozás tilos!';
        END IF;
        ALTER TABLE scanned_document
            ALTER COLUMN transaction_id TYPE BIGINT USING NULL;
    END IF;
END $$;

-- Index-védőháló: az ALTER COLUMN TYPE a függő b-tree indexeket automatikusan újraépíti
-- (Postgres dokumentált viselkedés), drop/recreate nem kell. Az IF NOT EXISTS csak arra
-- az esetre véd, ha valamely környezeten az index hiányozna.
CREATE INDEX IF NOT EXISTS idx_scanned_document_customer ON scanned_document(customer_id);
CREATE INDEX IF NOT EXISTS idx_scanned_document_transaction ON scanned_document(transaction_id);

-- Záró assertion (V348 precedens): pontosan 2 bigint oszlop a kettőből.
DO $$
DECLARE
    v_bigint_count INTEGER;
BEGIN
    SELECT COUNT(*)
      INTO v_bigint_count
      FROM pg_attribute
     WHERE attrelid = 'scanned_document'::regclass
       AND attname IN ('customer_id', 'transaction_id')
       AND NOT attisdropped
       AND atttypid = 'bigint'::regtype;
    IF v_bigint_count <> 2 THEN
        RAISE EXCEPTION 'V349: scanned_document.customer_id/transaction_id nem bigint a migráció végén (bigint-oszlopok: %)', v_bigint_count;
    END IF;
END $$;
