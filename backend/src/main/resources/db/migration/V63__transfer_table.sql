-- V63: Transfer tábla létrehozása (Transfer.java entity alapján)
CREATE TABLE IF NOT EXISTS transfer (
    id              BIGSERIAL PRIMARY KEY,
    transfer_number VARCHAR(30) NOT NULL UNIQUE,

    from_branch_id  UUID NOT NULL REFERENCES branch(id),
    to_branch_id    UUID NOT NULL REFERENCES branch(id),
    from_worker_id  BIGINT NOT NULL REFERENCES worker(id),
    to_worker_id    BIGINT REFERENCES worker(id),

    transfer_type   VARCHAR(20) NOT NULL,
    status          VARCHAR(20) NOT NULL,

    transfer_date   DATE NOT NULL,
    transfer_time   TIME NOT NULL,
    received_date   DATE,
    received_time   TIME,

    currency_id     BIGINT NOT NULL REFERENCES currency(id),
    amount          DECIMAL(18,4) NOT NULL,
    huf_value       DECIMAL(18,2),
    received_amount DECIMAL(18,4),
    difference      DECIMAL(18,4),

    notes           TEXT,
    handover_printed BOOLEAN DEFAULT false,
    receipt_printed  BOOLEAN DEFAULT false,

    created_at      TIMESTAMP NOT NULL DEFAULT now()
);

-- Indexek
CREATE INDEX IF NOT EXISTS idx_transfer_from_branch ON transfer(from_branch_id);
CREATE INDEX IF NOT EXISTS idx_transfer_to_branch ON transfer(to_branch_id);
CREATE INDEX IF NOT EXISTS idx_transfer_from_worker ON transfer(from_worker_id);
CREATE INDEX IF NOT EXISTS idx_transfer_currency ON transfer(currency_id);
CREATE INDEX IF NOT EXISTS idx_transfer_date ON transfer(transfer_date);
CREATE INDEX IF NOT EXISTS idx_transfer_status ON transfer(status);
