-- V26: Trade tábla — devizakereskedés irodák között
CREATE TABLE trade (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_branch_id  UUID NOT NULL REFERENCES branch(id),
    to_branch_id    UUID NOT NULL REFERENCES branch(id),
    currency_code   VARCHAR(10) NOT NULL,
    amount          NUMERIC(18,4) NOT NULL,
    rate            NUMERIC(18,6) NOT NULL DEFAULT 1.0,
    status          VARCHAR(20) NOT NULL DEFAULT 'PROPOSED',
    proposed_by     BIGINT NOT NULL,
    accepted_by     BIGINT,
    proposed_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    accepted_at     TIMESTAMP,
    completed_at    TIMESTAMP,
    notes           TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_trade_status CHECK (status IN ('PROPOSED','ACCEPTED','REJECTED','COMPLETED','CANCELLED')),
    CONSTRAINT chk_trade_branches CHECK (from_branch_id <> to_branch_id)
);

CREATE INDEX idx_trade_from_branch ON trade(from_branch_id);
CREATE INDEX idx_trade_to_branch ON trade(to_branch_id);
CREATE INDEX idx_trade_status ON trade(status);
CREATE INDEX idx_trade_proposed_at ON trade(proposed_at);
