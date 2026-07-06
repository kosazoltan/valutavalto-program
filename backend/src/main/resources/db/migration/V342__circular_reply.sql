-- V342: FS-C (Center FS-1) — körlevél kétirányú válasz
-- allows_reply: a center jelöli, hogy a körlevélre várható-e pénztárosi válasz.
-- DEFAULT false → minden meglévő körlevél változatlanul válasz-tiltott (backward-compat).
ALTER TABLE circular ADD COLUMN IF NOT EXISTS allows_reply BOOLEAN NOT NULL DEFAULT false;

-- Pénztárosi szabadszöveges válaszok (több válasz/worker megengedett — nincs unique).
CREATE TABLE IF NOT EXISTS circular_reply (
    id BIGSERIAL PRIMARY KEY,
    circular_id BIGINT NOT NULL REFERENCES circular(id) ON DELETE CASCADE,
    worker_id BIGINT NOT NULL,
    company_id UUID NOT NULL,
    branch_id UUID,
    reply_text TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_circ_reply_circular ON circular_reply(circular_id);
CREATE INDEX IF NOT EXISTS idx_circ_reply_company ON circular_reply(company_id, circular_id);
