-- V39: Szkennelt dokumentumok
-- Ügyfél-azonosításhoz szükséges dokumentumok (személyi ig., útlevél, jogosítvány)

CREATE TABLE IF NOT EXISTS scanned_document (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID,
    transaction_id UUID,
    document_type VARCHAR(30) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    mime_type VARCHAR(100),
    file_size_bytes BIGINT,
    storage_path VARCHAR(500),
    scanned_by BIGINT,
    scanned_at TIMESTAMP NOT NULL DEFAULT NOW(),
    notes VARCHAR(500),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_scanned_document_customer ON scanned_document(customer_id);
CREATE INDEX idx_scanned_document_transaction ON scanned_document(transaction_id);
CREATE INDEX idx_scanned_document_type ON scanned_document(document_type);
