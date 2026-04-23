-- V157: Ertektar leltar (stocktake) workflow - Sprint 7.1
--
-- Legacy: LELTAR.DLL (eves/alkalmi tetelés ertektar ellenorzes)
-- Modern:
--  - vault_stocktake_session: leltar fejleg (OPEN -> IN_PROGRESS -> REVIEW -> CLOSED)
--  - vault_stocktake_item:    tetelek (varhato vs. tenyleges)
--
-- Jovahagyas: csak FOERTEKTAR, UGYVEZETO, ADMIN

-- 1. Fejleg
CREATE TABLE vault_stocktake_session (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id      UUID NOT NULL REFERENCES company(id),
    branch_id       UUID REFERENCES branch(id),         -- NULL = ertektar szintu leltar
    territory_id    INT REFERENCES vault_territory(id), -- opcionalis: adott teruleti leltar
    session_name    VARCHAR(200) NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'OPEN', -- OPEN, IN_PROGRESS, REVIEW, CLOSED, CANCELLED
    started_at      TIMESTAMP NOT NULL DEFAULT now(),
    completed_at    TIMESTAMP,
    started_by      VARCHAR(100) NOT NULL,
    reviewed_by     VARCHAR(100),
    approved_by     VARCHAR(100),
    note            TEXT,
    discrepancy_total_huf DECIMAL(20, 2) DEFAULT 0,  -- ossz eltéres HUF-ben
    created_at      TIMESTAMP DEFAULT now(),
    updated_at      TIMESTAMP DEFAULT now(),
    version         BIGINT DEFAULT 0
);

CREATE INDEX idx_vault_stocktake_session_company ON vault_stocktake_session(company_id);
CREATE INDEX idx_vault_stocktake_session_branch  ON vault_stocktake_session(branch_id);
CREATE INDEX idx_vault_stocktake_session_status  ON vault_stocktake_session(status);
CREATE INDEX idx_vault_stocktake_session_started ON vault_stocktake_session(started_at DESC);

COMMENT ON TABLE vault_stocktake_session IS 'Ertektar leltar munkafolyamat fejleg (Sprint 7.1)';
COMMENT ON COLUMN vault_stocktake_session.status IS 'OPEN: uj, IN_PROGRESS: felvetel alatt, REVIEW: ellenorzes, CLOSED: lezart, CANCELLED: torolve';

-- 2. Tetelek
CREATE TABLE vault_stocktake_item (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id          UUID NOT NULL REFERENCES vault_stocktake_session(id) ON DELETE CASCADE,
    currency_id         BIGINT NOT NULL REFERENCES currency(id),
    currency_code       VARCHAR(3) NOT NULL,
    face_value          DECIMAL(20, 4) NOT NULL,       -- cimlet (20 EUR, 100 USD, stb.)
    expected_quantity   INT NOT NULL DEFAULT 0,         -- varhato cimletszam (vault_cash_balance-bol)
    actual_quantity     INT,                             -- manualis felvetel utan
    discrepancy         INT GENERATED ALWAYS AS (COALESCE(actual_quantity, expected_quantity) - expected_quantity) STORED,
    discrepancy_value   DECIMAL(20, 2) GENERATED ALWAYS AS ((COALESCE(actual_quantity, expected_quantity) - expected_quantity) * face_value) STORED,
    counted_by          VARCHAR(100),
    counted_at          TIMESTAMP,
    note                TEXT,
    created_at          TIMESTAMP DEFAULT now(),
    updated_at          TIMESTAMP DEFAULT now(),
    version             BIGINT DEFAULT 0,
    CONSTRAINT uk_stocktake_item UNIQUE (session_id, currency_id, face_value)
);

CREATE INDEX idx_vault_stocktake_item_session ON vault_stocktake_item(session_id);
CREATE INDEX idx_vault_stocktake_item_currency ON vault_stocktake_item(currency_id);
CREATE INDEX idx_vault_stocktake_item_discrepancy ON vault_stocktake_item(discrepancy) WHERE discrepancy <> 0;

COMMENT ON TABLE vault_stocktake_item IS 'Ertektar leltar tetelei - cimletenkenti szamlalás (Sprint 7.1)';
COMMENT ON COLUMN vault_stocktake_item.discrepancy IS 'Generated: actual - expected (negatí=hiany, pozití=tobblet)';
COMMENT ON COLUMN vault_stocktake_item.discrepancy_value IS 'Generated: eltéres HUF/valuta osszege';
