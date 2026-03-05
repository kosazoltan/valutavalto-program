-- V6: MNB adatszolgáltatási riportok
-- JOGSZABÁLYI KÖTELEZETTSÉG: Magyar Nemzeti Bank felé kötelező napi/heti/havi riport

-- MNB riportok fejléc tábla
CREATE TABLE mnb_report (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_type   VARCHAR(20)  NOT NULL,  -- DAILY/WEEKLY/MONTHLY/QUARTERLY/YEARLY
    report_date   DATE         NOT NULL,
    status        VARCHAR(20)  NOT NULL DEFAULT 'DRAFT',  -- DRAFT/SUBMITTED/ACCEPTED/REJECTED
    branch_id     UUID         NOT NULL REFERENCES branch(id),
    total_buy_huf NUMERIC(18,2) DEFAULT 0,
    total_sell_huf NUMERIC(18,2) DEFAULT 0,
    total_transactions INTEGER DEFAULT 0,
    submitted_at  TIMESTAMP,
    accepted_at   TIMESTAMP,
    rejection_reason VARCHAR(1000),
    xml_content   TEXT,
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP
);

-- Indexek
CREATE INDEX idx_mnb_report_type_date    ON mnb_report(report_type, report_date);
CREATE INDEX idx_mnb_report_branch_date  ON mnb_report(branch_id, report_date);
CREATE INDEX idx_mnb_report_status       ON mnb_report(status);

-- Egyediség: egy irodához egy típusú riport egy adott dátumra
CREATE UNIQUE INDEX uq_mnb_report_branch_type_date
    ON mnb_report(branch_id, report_type, report_date);

-- MNB riport sorok (valutánkénti bontás)
CREATE TABLE mnb_report_line (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mnb_report_id     UUID         NOT NULL REFERENCES mnb_report(id) ON DELETE CASCADE,
    currency_code     VARCHAR(3)   NOT NULL,
    buy_amount        NUMERIC(18,2) DEFAULT 0,
    sell_amount       NUMERIC(18,2) DEFAULT 0,
    buy_rate          NUMERIC(12,4) DEFAULT 0,
    sell_rate         NUMERIC(12,4) DEFAULT 0,
    transaction_count INTEGER      DEFAULT 0
);

CREATE INDEX idx_mnb_line_report   ON mnb_report_line(mnb_report_id);
CREATE INDEX idx_mnb_line_currency ON mnb_report_line(currency_code);
