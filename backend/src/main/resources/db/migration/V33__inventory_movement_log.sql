-- V33: Készlet mozgás napló bővítés (balance tracking)
-- A tábla V3_5__create_missing_tables_guard.sql-ben kerül létrehozásra (fresh install guard)
CREATE TABLE IF NOT EXISTS inventory_movement (
    id               BIGSERIAL PRIMARY KEY,
    from_branch_id   UUID,
    to_branch_id     UUID,
    currency_id      BIGINT       NOT NULL,
    amount           NUMERIC(18,4) NOT NULL,
    huf_value        NUMERIC(18,2),
    movement_type    VARCHAR(30)  NOT NULL,
    status           VARCHAR(20)  NOT NULL DEFAULT 'PENDING',
    initiated_by_id  BIGINT       NOT NULL,
    approved_by_id   BIGINT,
    received_by_id   BIGINT,
    reference_number VARCHAR(30)  NOT NULL,
    notes            TEXT,
    movement_date    DATE         NOT NULL,
    movement_time    TIME         NOT NULL,
    approved_at      TIMESTAMP,
    received_at      TIMESTAMP,
    created_at       TIMESTAMP    NOT NULL DEFAULT NOW(),

    CONSTRAINT uk_inv_mov_ref_number UNIQUE (reference_number),
    CONSTRAINT fk_inv_mov_from_branch  FOREIGN KEY (from_branch_id)  REFERENCES branch(id),
    CONSTRAINT fk_inv_mov_to_branch    FOREIGN KEY (to_branch_id)    REFERENCES branch(id),
    CONSTRAINT fk_inv_mov_currency     FOREIGN KEY (currency_id)     REFERENCES currency(id),
    CONSTRAINT fk_inv_mov_initiated_by FOREIGN KEY (initiated_by_id) REFERENCES worker(id),
    CONSTRAINT fk_inv_mov_approved_by  FOREIGN KEY (approved_by_id)  REFERENCES worker(id),
    CONSTRAINT fk_inv_mov_received_by  FOREIGN KEY (received_by_id)  REFERENCES worker(id)
);

-- Base indexes (V74 will also run IF NOT EXISTS, safely)
CREATE INDEX IF NOT EXISTS idx_inv_mov_from_branch ON inventory_movement(from_branch_id);
CREATE INDEX IF NOT EXISTS idx_inv_mov_to_branch   ON inventory_movement(to_branch_id);
CREATE INDEX IF NOT EXISTS idx_inv_mov_currency    ON inventory_movement(currency_id);
CREATE INDEX IF NOT EXISTS idx_inv_mov_date        ON inventory_movement(movement_date);
CREATE INDEX IF NOT EXISTS idx_inv_mov_status      ON inventory_movement(status);

-- Balance tracking mezők hozzáadása
ALTER TABLE inventory_movement ADD COLUMN IF NOT EXISTS balance_before DECIMAL(18,4);
ALTER TABLE inventory_movement ADD COLUMN IF NOT EXISTS balance_after DECIMAL(18,4);
ALTER TABLE inventory_movement ADD COLUMN IF NOT EXISTS transaction_id BIGINT;
ALTER TABLE inventory_movement ADD COLUMN IF NOT EXISTS worker_id BIGINT;

CREATE INDEX IF NOT EXISTS idx_inv_mov_transaction ON inventory_movement(transaction_id);
CREATE INDEX IF NOT EXISTS idx_inv_mov_worker ON inventory_movement(worker_id);
