-- V33: Készlet mozgás napló bővítés (balance tracking)
-- A tábla definíciója: V3_5__create_missing_tables_guard.sql (kanonikus, fresh install guard)
-- Ez a migration csak az ALTER TABLE bővítéseket tartalmazza.

-- Balance tracking mezők hozzáadása
ALTER TABLE inventory_movement ADD COLUMN IF NOT EXISTS balance_before DECIMAL(18,4);
ALTER TABLE inventory_movement ADD COLUMN IF NOT EXISTS balance_after DECIMAL(18,4);
ALTER TABLE inventory_movement ADD COLUMN IF NOT EXISTS transaction_id BIGINT;
ALTER TABLE inventory_movement ADD COLUMN IF NOT EXISTS worker_id BIGINT;

-- Indexek (V74 is lefuttatja IF NOT EXISTS, biztonságosan duplikálható)
CREATE INDEX IF NOT EXISTS idx_inv_mov_from_branch ON inventory_movement(from_branch_id);
CREATE INDEX IF NOT EXISTS idx_inv_mov_to_branch   ON inventory_movement(to_branch_id);
CREATE INDEX IF NOT EXISTS idx_inv_mov_currency    ON inventory_movement(currency_id);
CREATE INDEX IF NOT EXISTS idx_inv_mov_date        ON inventory_movement(movement_date);
CREATE INDEX IF NOT EXISTS idx_inv_mov_status      ON inventory_movement(status);
CREATE INDEX IF NOT EXISTS idx_inv_mov_transaction ON inventory_movement(transaction_id);
CREATE INDEX IF NOT EXISTS idx_inv_mov_worker      ON inventory_movement(worker_id);
