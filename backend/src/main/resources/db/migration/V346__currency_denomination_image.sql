-- FS-9 S1: valuta-címletképek (center feltöltés → pénztár sync-fetch), cégenkénti tárolás.
-- Új tábla (nincs ALTER → nincs ownership-csapda, PROD-502-tanulság).
-- FK szándékosan NINCS (V39/V77 típus-drift tanulság; V345 precedens): UNIQUE + index védi.
CREATE TABLE IF NOT EXISTS currency_denomination_image (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    company_id UUID NOT NULL,
    currency_id BIGINT NOT NULL,
    face_value NUMERIC(15,2) NOT NULL,
    denomination_type VARCHAR(20) NOT NULL,
    side VARCHAR(10) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    file_data BYTEA NOT NULL,
    thumbnail_data BYTEA,
    thumbnail_mime_type VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by_worker_code VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP,
    CONSTRAINT ux_cdi_company_currency_face_type_side
        UNIQUE (company_id, currency_id, face_value, denomination_type, side)
);
CREATE INDEX IF NOT EXISTS idx_cdi_company_currency
    ON currency_denomination_image (company_id, currency_id);
