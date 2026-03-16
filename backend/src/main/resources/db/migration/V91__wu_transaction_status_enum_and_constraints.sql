-- V91: WU tranzakciók megerősítése — status enum, transaction_type CHECK, reversal FK, WuCustomer unique index
-- Legacy: WUNION.DLL — WUMOZGAS tábla megerősítése

-- 1. Meglévő status értékek normalzálása (COMPLETED → COMPLETED, stb.)
UPDATE wu_transactions SET status = 'COMPLETED' WHERE status IS NULL OR status NOT IN ('PENDING','COMPLETED','REVERSED','FAILED');

-- 2. status CHECK constraint
ALTER TABLE wu_transactions
    ADD CONSTRAINT chk_wu_transactions_status
    CHECK (status IN ('PENDING','COMPLETED','REVERSED','FAILED'));

-- 3. transaction_type értékek normalzálása (IC_IN, IC_OUT, CUSTOMER_IN, CUSTOMER_OUT, STORNO)
UPDATE wu_transactions
    SET transaction_type = 'SEND'
    WHERE transaction_type IS NULL
       OR transaction_type NOT IN ('SEND','RECEIVE','IC_IN','IC_OUT','CUSTOMER_IN','CUSTOMER_OUT','STORNO');

-- 4. transaction_type CHECK constraint
ALTER TABLE wu_transactions
    ADD CONSTRAINT chk_wu_transactions_type
    CHECK (transaction_type IN ('SEND','RECEIVE','IC_IN','IC_OUT','CUSTOMER_IN','CUSTOMER_OUT','STORNO'));

-- 5. reversed_transaction_id mező és FK (storno link az eredeti tranzakcióra)
ALTER TABLE wu_transactions
    ADD COLUMN IF NOT EXISTS reversed_transaction_id UUID NULL;

ALTER TABLE wu_transactions
    ADD CONSTRAINT fk_wu_transactions_reversed
    FOREIGN KEY (reversed_transaction_id)
    REFERENCES wu_transactions(id)
    ON DELETE SET NULL;

-- 6. reversal_reason szöveges mező
ALTER TABLE wu_transactions
    ADD COLUMN IF NOT EXISTS reversal_reason VARCHAR(500) NULL;

-- 7. WuCustomer egyedi index — azonos névű + dokumentumszámú ügyfél ne duplikálódjon
CREATE UNIQUE INDEX IF NOT EXISTS uq_wu_customers_name_document
    ON wu_customers (last_name, first_name, id_number)
    WHERE id_number IS NOT NULL;
