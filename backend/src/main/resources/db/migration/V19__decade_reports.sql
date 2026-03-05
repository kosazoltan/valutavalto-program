-- V19: Dekádjelentés (10 napos összesítő)
CREATE TABLE decade_report (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id       UUID NOT NULL REFERENCES branch(id),
    year            INTEGER NOT NULL,
    decade          INTEGER NOT NULL CHECK (decade BETWEEN 1 AND 36),
    total_buy_huf   NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_sell_huf  NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_handling_fee NUMERIC(18,2) NOT NULL DEFAULT 0,
    transaction_count INTEGER NOT NULL DEFAULT 0,
    status          VARCHAR(20) NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'CLOSED')),
    closed_at       TIMESTAMP,
    closed_by       BIGINT,
    created_at      TIMESTAMP NOT NULL DEFAULT now(),
    updated_at      TIMESTAMP,
    UNIQUE (branch_id, year, decade)
);

CREATE INDEX idx_decade_report_branch ON decade_report(branch_id);
CREATE INDEX idx_decade_report_year ON decade_report(year);
