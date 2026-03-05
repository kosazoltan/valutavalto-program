-- V7: NAV zárás (adóhatósági kötelezettség)
-- Napi/havi zárás — bevétel, kiadás, kezelési díj, ÁFA

-- NAV zárás fejléc
CREATE TABLE nav_closing (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    closing_date         DATE         NOT NULL,
    branch_id            UUID         NOT NULL REFERENCES branch(id),
    closing_type         VARCHAR(20)  NOT NULL,  -- DAILY/MONTHLY/YEARLY
    total_revenue        NUMERIC(18,2) DEFAULT 0,
    total_expense        NUMERIC(18,2) DEFAULT 0,
    handling_fee_total   NUMERIC(18,2) DEFAULT 0,
    vat_amount           NUMERIC(18,2) DEFAULT 0,
    status               VARCHAR(20)  NOT NULL DEFAULT 'OPEN',  -- OPEN/CLOSED/SUBMITTED/VERIFIED
    nav_reference_number VARCHAR(100),
    closed_by            BIGINT       REFERENCES worker(id),
    closed_at            TIMESTAMP,
    created_at           TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMP
);

-- Indexek
CREATE INDEX idx_nav_closing_branch_date ON nav_closing(branch_id, closing_date);
CREATE INDEX idx_nav_closing_status      ON nav_closing(status);
CREATE INDEX idx_nav_closing_type_date   ON nav_closing(closing_type, closing_date);

-- Egyediség: egy irodához egy típusú zárás egy adott dátumra
CREATE UNIQUE INDEX uq_nav_closing_branch_type_date
    ON nav_closing(branch_id, closing_type, closing_date);

-- NAV zárás sorok (valutánkénti bontás)
CREATE TABLE nav_closing_line (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nav_closing_id    UUID         NOT NULL REFERENCES nav_closing(id) ON DELETE CASCADE,
    currency_code     VARCHAR(3)   NOT NULL,
    buy_amount        NUMERIC(18,2) DEFAULT 0,
    sell_amount       NUMERIC(18,2) DEFAULT 0,
    buy_huf           NUMERIC(18,2) DEFAULT 0,
    sell_huf          NUMERIC(18,2) DEFAULT 0,
    handling_fee      NUMERIC(18,2) DEFAULT 0,
    transaction_count INTEGER      DEFAULT 0
);

CREATE INDEX idx_nav_line_closing  ON nav_closing_line(nav_closing_id);
CREATE INDEX idx_nav_line_currency ON nav_closing_line(currency_code);
