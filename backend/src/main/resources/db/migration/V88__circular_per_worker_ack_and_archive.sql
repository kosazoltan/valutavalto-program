-- V88: Körlevél rendszer legacy paritás — per-worker nyugtázás, archiválás, company szűrés, auto-sorszám
-- Legacy KORLEVEL: AT.xxx fájlok per dolgozó, LASTYEAR/ARCHIVE mappák, FZS/BT/KI prefix sorszámozás

-- 1. Company szűrés hozzáadása (multi-tenant!)
ALTER TABLE circular ADD COLUMN IF NOT EXISTS company_id UUID;
CREATE INDEX IF NOT EXISTS idx_circular_company ON circular(company_id);

-- Meglévő rekordok frissítése: az első company-hoz rendeljük
UPDATE circular SET company_id = (SELECT id FROM company LIMIT 1) WHERE company_id IS NULL;

-- 2. Per-worker nyugtázás tábla (legacy: AT.xxx fájlok)
CREATE TABLE IF NOT EXISTS circular_acknowledgment (
    id BIGSERIAL PRIMARY KEY,
    circular_id BIGINT NOT NULL REFERENCES circular(id) ON DELETE CASCADE,
    worker_id BIGINT NOT NULL,
    acknowledged_at TIMESTAMP NOT NULL DEFAULT NOW(),
    ip_address VARCHAR(45),
    UNIQUE(circular_id, worker_id)
);

CREATE INDEX idx_circ_ack_circular ON circular_acknowledgment(circular_id);
CREATE INDEX idx_circ_ack_worker ON circular_acknowledgment(worker_id);
CREATE INDEX idx_circ_ack_unacked ON circular_acknowledgment(circular_id, worker_id);

-- 3. Archiválás mezők
ALTER TABLE circular ADD COLUMN IF NOT EXISTS archived BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE circular ADD COLUMN IF NOT EXISTS archived_at TIMESTAMP;
ALTER TABLE circular ADD COLUMN IF NOT EXISTS archive_year INTEGER;

CREATE INDEX IF NOT EXISTS idx_circular_archived ON circular(archived, company_id);

-- 4. Auto-sorszám tracking per típus prefix
CREATE TABLE IF NOT EXISTS circular_sequence (
    id SERIAL PRIMARY KEY,
    company_id UUID NOT NULL,
    prefix VARCHAR(10) NOT NULL,
    last_number INTEGER NOT NULL DEFAULT 0,
    UNIQUE(company_id, prefix)
);

-- 5. Kategória mező (legacy mappa: VIP, ZALOG, vagy gyökér)
ALTER TABLE circular ADD COLUMN IF NOT EXISTS category VARCHAR(20) NOT NULL DEFAULT 'GENERAL';
CREATE INDEX IF NOT EXISTS idx_circular_category ON circular(company_id, category);

-- 6. Fájl méret mező
ALTER TABLE circular ADD COLUMN IF NOT EXISTS attachment_size BIGINT;
