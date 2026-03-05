-- V33: Készlet mozgás napló bővítés (balance tracking)
-- Az inventory_movement tábla már létezik, de hozzáadjuk a balance tracking mezőket
ALTER TABLE inventory_movement ADD COLUMN IF NOT EXISTS balance_before DECIMAL(18,4);
ALTER TABLE inventory_movement ADD COLUMN IF NOT EXISTS balance_after DECIMAL(18,4);
ALTER TABLE inventory_movement ADD COLUMN IF NOT EXISTS transaction_id BIGINT;
ALTER TABLE inventory_movement ADD COLUMN IF NOT EXISTS worker_id BIGINT;

CREATE INDEX IF NOT EXISTS idx_inv_mov_transaction ON inventory_movement(transaction_id);
CREATE INDEX IF NOT EXISTS idx_inv_mov_worker ON inventory_movement(worker_id);
