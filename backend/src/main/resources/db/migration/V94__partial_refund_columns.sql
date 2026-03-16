-- V94: Részleges visszatérítés (partial refund) mezők a transaction táblában
-- P3-15: StornoService.executeOtpRefund() valódi részleges visszatérítés logika

ALTER TABLE transaction ADD COLUMN IF NOT EXISTS partial_refund_amount NUMERIC(18,4);

-- original_transaction_id már létezik (V1-ben lett létrehozva), index hiányozhat
CREATE INDEX IF NOT EXISTS idx_transaction_original_id
    ON transaction(original_transaction_id)
    WHERE original_transaction_id IS NOT NULL;
