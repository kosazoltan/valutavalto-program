-- V97: Seal tracking for transfer lifecycle (plomba nyomkövetés)
CREATE TABLE seal_tracking (
    id              BIGSERIAL PRIMARY KEY,
    company_id      UUID NOT NULL REFERENCES company(id),
    transfer_type   VARCHAR(20) NOT NULL,
    transfer_id     BIGINT NOT NULL,
    seal_number     VARCHAR(50) NOT NULL,
    sealed_at       TIMESTAMP NOT NULL,
    sealed_by       BIGINT NOT NULL REFERENCES worker(id),
    opened_at       TIMESTAMP,
    opened_by       BIGINT REFERENCES worker(id),
    transit_status  VARCHAR(20) NOT NULL DEFAULT 'SEALED',
    notes           TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP
);

CREATE INDEX idx_seal_tracking_transfer ON seal_tracking(transfer_type, transfer_id);
CREATE UNIQUE INDEX idx_seal_tracking_number ON seal_tracking(seal_number);
CREATE INDEX idx_seal_tracking_company ON seal_tracking(company_id);
CREATE INDEX idx_seal_tracking_status ON seal_tracking(transit_status) WHERE transit_status IN ('SEALED', 'IN_TRANSIT');
