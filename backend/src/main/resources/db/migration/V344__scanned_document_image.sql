-- FS-5: okmány elő/hátlap képpár — a képbájtok TÉNYLEGES perzisztálása (center-only tárolás).
-- Új tábla (nincs meglévő-tábla ALTER → nincs ownership-csapda).
-- FK CSAK a scanned_document(id)-re (UUID mindkét sémavilágban); customer_id-ra TILOS (V39-eltérés).
CREATE TABLE IF NOT EXISTS scanned_document_image (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    scanned_document_id UUID NOT NULL REFERENCES scanned_document(id),
    side VARCHAR(10) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    file_data BYTEA NOT NULL,
    thumbnail_data BYTEA,
    thumbnail_mime_type VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT ux_sdi_document_side UNIQUE (scanned_document_id, side)
);
CREATE INDEX IF NOT EXISTS idx_sdi_document ON scanned_document_image(scanned_document_id);
