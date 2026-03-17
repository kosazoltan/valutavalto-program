-- V71: Árfolyam törzs adatbázis (Exchange Rate Master)
-- A főértéktáros által beállított árfolyamok központi törzstáblája.
-- Legacy: ARFOLYAM tábla + ARFREG modul - központi árfolyam kezelés
-- Ez a tábla tárolja az összes kiadott árfolyamot verziókezeléssel,
-- és biztosítja az árfolyamok automatikus elosztását a pénztáraknak.

CREATE TABLE exchange_rate_master (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id      UUID NOT NULL REFERENCES company(id),
    currency_id     BIGINT NOT NULL REFERENCES currency(id),

    -- Alap árfolyamok (főértéktáros által beállított)
    base_buy_rate   NUMERIC(18,6) NOT NULL,
    base_sell_rate  NUMERIC(18,6) NOT NULL,
    official_rate   NUMERIC(18,6),

    -- Limit szintű árfolyamok (nagyobb összegekhez)
    limit1_amount   NUMERIC(15,2),
    limit1_buy_rate NUMERIC(18,6),
    limit1_sell_rate NUMERIC(18,6),
    limit2_amount   NUMERIC(15,2),
    limit2_buy_rate NUMERIC(18,6),
    limit2_sell_rate NUMERIC(18,6),
    limit3_amount   NUMERIC(15,2),
    limit3_buy_rate NUMERIC(18,6),
    limit3_sell_rate NUMERIC(18,6),

    -- Állapot és audit
    status          VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    version_number  INTEGER NOT NULL DEFAULT 1,
    valid_from      TIMESTAMP NOT NULL DEFAULT NOW(),
    valid_until     TIMESTAMP,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,

    -- Ki készítette / hagyta jóvá
    created_by      BIGINT NOT NULL,
    approved_by     BIGINT,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    approved_at     TIMESTAMP,
    notes           TEXT,

    CONSTRAINT chk_master_sell_gt_buy CHECK (base_sell_rate > base_buy_rate),
    CONSTRAINT chk_master_status CHECK (status IN ('DRAFT', 'APPROVED', 'PUBLISHED', 'REVOKED', 'ARCHIVED'))
);

CREATE INDEX idx_erm_company_currency ON exchange_rate_master(company_id, currency_id);
CREATE INDEX idx_erm_status ON exchange_rate_master(status);
CREATE INDEX idx_erm_active ON exchange_rate_master(is_active, valid_from);
CREATE INDEX idx_erm_valid_from ON exchange_rate_master(valid_from DESC);

-- Árfolyam elosztás napló - melyik pénztár kapta meg az árfolyamot
CREATE TABLE exchange_rate_distribution (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    master_rate_id  UUID NOT NULL REFERENCES exchange_rate_master(id),
    branch_id       UUID NOT NULL REFERENCES branch(id),
    exchange_rate_id BIGINT REFERENCES exchange_rate(id),
    distributed_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    acknowledged_at TIMESTAMP,
    error_message   TEXT,

    CONSTRAINT chk_dist_status CHECK (status IN ('PENDING', 'DISTRIBUTED', 'ACKNOWLEDGED', 'FAILED'))
);

CREATE INDEX idx_erd_master ON exchange_rate_distribution(master_rate_id);
CREATE INDEX idx_erd_branch ON exchange_rate_distribution(branch_id);
CREATE INDEX idx_erd_status ON exchange_rate_distribution(status);

COMMENT ON TABLE exchange_rate_master IS 'Árfolyam törzs: a főértéktáros által beállított központi árfolyamok';
COMMENT ON TABLE exchange_rate_distribution IS 'Árfolyam elosztás: mely pénztárak kapták meg az árfolyamot';
COMMENT ON COLUMN exchange_rate_master.status IS 'DRAFT=piszkozat, APPROVED=jóváhagyva, PUBLISHED=kiküldve, REVOKED=visszavonva, ARCHIVED=archivált';
