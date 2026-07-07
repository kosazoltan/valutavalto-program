-- FS-5: okmány full-res megtekintés engedély (törvényi: személyi adattal visszaélés elleni védelem).
-- Az FS-2 aml_approval_grant mintája: SINGLE-USE, atomikus consume, lejárattal.
CREATE TABLE IF NOT EXISTS document_view_grant (
    id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL,
    requester_worker_id BIGINT NOT NULL,
    approver_worker_id BIGINT NOT NULL,
    document_id UUID NOT NULL REFERENCES scanned_document(id),
    created_at TIMESTAMP NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    uses_remaining INT NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_document_view_grant_consume
    ON document_view_grant (company_id, requester_worker_id, document_id, uses_remaining);
