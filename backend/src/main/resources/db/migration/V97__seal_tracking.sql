-- V97: Seal tracking for transfer lifecycle (plomba nyomkövetés)
CREATE TABLE seal_tracking (
    id              BIGSERIAL PRIMARY KEY,
    version         BIGINT NOT NULL DEFAULT 0,
    company_id      UUID NOT NULL REFERENCES company(id),
    transfer_type   VARCHAR(20) NOT NULL,
    transfer_id     BIGINT NOT NULL,
    seal_number     VARCHAR(50) NOT NULL,
    sealed_at       TIMESTAMP NOT NULL,
    sealed_by       BIGINT NOT NULL REFERENCES worker(id),
    opened_at       TIMESTAMP,
    opened_by       BIGINT REFERENCES worker(id),
    transit_status  VARCHAR(20) NOT NULL DEFAULT 'SEALED'
        CHECK (transit_status IN ('SEALED', 'IN_TRANSIT', 'ARRIVED', 'OPENED')),
    notes           TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP
);

CREATE INDEX idx_seal_tracking_transfer ON seal_tracking(transfer_type, transfer_id);
-- Per-company unique seal number (not global)
CREATE UNIQUE INDEX uq_seal_tracking_company_seal ON seal_tracking(company_id, seal_number);
CREATE INDEX idx_seal_tracking_company ON seal_tracking(company_id);
CREATE INDEX idx_seal_tracking_company_status ON seal_tracking(company_id, transit_status)
    WHERE transit_status IN ('SEALED', 'IN_TRANSIT');
