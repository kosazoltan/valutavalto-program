-- V154: VaultBankTransaction workflow timestamps
-- A banki tranzakcio reszletes allapotkovetesre kiegeszitjuk a meglevo tablat.
-- REQUESTED -> IN_PROGRESS (bank visszaigazolta) -> COMPLETED (deviza+HUF egyaztatva)
--
-- Uj mezok:
--   received_at        - mikor erkezett meg a deviza az ertektarba (BUY)
--   received_by        - ki igazolta (worker id)
--   paid_at            - mikor tortent meg a HUF atutalas (mindket iranyban)
--   paid_by            - ki igazolta

ALTER TABLE vault_bank_transaction
    ADD COLUMN IF NOT EXISTS received_at  TIMESTAMP,
    ADD COLUMN IF NOT EXISTS received_by  BIGINT REFERENCES worker(id),
    ADD COLUMN IF NOT EXISTS paid_at      TIMESTAMP,
    ADD COLUMN IF NOT EXISTS paid_by      BIGINT REFERENCES worker(id);

CREATE INDEX IF NOT EXISTS idx_vault_bank_transaction_received_at ON vault_bank_transaction(received_at);
CREATE INDEX IF NOT EXISTS idx_vault_bank_transaction_paid_at ON vault_bank_transaction(paid_at);

COMMENT ON COLUMN vault_bank_transaction.received_at IS 'BUY-nal: deviza beerkezesenek idopontja. SELL-nel: bankba atadas idopontja.';
COMMENT ON COLUMN vault_bank_transaction.paid_at IS 'HUF atutalasanak idopontja.';
