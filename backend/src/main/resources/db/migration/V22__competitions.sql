-- V22: Pénztáros versenyeztetés
CREATE TABLE worker_competition (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    competition_name    VARCHAR(255) NOT NULL,
    start_date          DATE NOT NULL,
    end_date            DATE NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'CLOSED')),
    rules               TEXT,
    created_at          TIMESTAMP NOT NULL DEFAULT now(),
    updated_at          TIMESTAMP
);

CREATE TABLE worker_competition_entry (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    competition_id      UUID NOT NULL REFERENCES worker_competition(id),
    worker_id           BIGINT NOT NULL,
    total_volume        NUMERIC(18,2) NOT NULL DEFAULT 0,
    transaction_count   INTEGER NOT NULL DEFAULT 0,
    score               NUMERIC(18,4) NOT NULL DEFAULT 0,
    rank                INTEGER,
    created_at          TIMESTAMP NOT NULL DEFAULT now(),
    updated_at          TIMESTAMP,
    UNIQUE (competition_id, worker_id)
);

CREATE INDEX idx_competition_status ON worker_competition(status);
CREATE INDEX idx_comp_entry_competition ON worker_competition_entry(competition_id);
CREATE INDEX idx_comp_entry_worker ON worker_competition_entry(worker_id);
