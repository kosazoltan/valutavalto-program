-- V16: Matrica pénztár — előnyomott bizonylat sorszámok kezelése
CREATE TABLE IF NOT EXISTS stamp_batch (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id      UUID NOT NULL,
    branch_id       UUID NOT NULL,
    serial_prefix   VARCHAR(10) NOT NULL,
    serial_start    INTEGER NOT NULL,
    serial_end      INTEGER NOT NULL,
    received_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    received_by     VARCHAR(100),
    note            VARCHAR(500),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_stamp_batch_branch ON stamp_batch(branch_id);
CREATE INDEX idx_stamp_batch_company ON stamp_batch(company_id);

CREATE TABLE IF NOT EXISTS stamp_assignment (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stamp_batch_id  UUID NOT NULL REFERENCES stamp_batch(id),
    serial_number   VARCHAR(20) NOT NULL UNIQUE,
    transaction_id  BIGINT,
    assigned_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    assigned_by     VARCHAR(100),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_stamp_assignment_batch ON stamp_assignment(stamp_batch_id);
CREATE INDEX idx_stamp_assignment_serial ON stamp_assignment(serial_number);
CREATE INDEX idx_stamp_assignment_tx ON stamp_assignment(transaction_id);
