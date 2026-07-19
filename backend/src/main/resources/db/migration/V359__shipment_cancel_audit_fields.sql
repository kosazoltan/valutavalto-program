ALTER TABLE shipment_request
    ADD COLUMN cancelled_by_worker_id BIGINT,
    ADD COLUMN cancelled_at TIMESTAMP;

COMMENT ON COLUMN shipment_request.cancelled_by_worker_id IS
    'FKH-018: a kuldoi sztornot rogzitő dolgozo az irattari bizonylathoz';

CREATE INDEX IF NOT EXISTS idx_shipment_request_to_branch_status
    ON shipment_request (to_branch_id, status);