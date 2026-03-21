-- Darius/Raiffeisen napi jelentés modul
-- V100: darius_daily_report + darius_report_line

CREATE TABLE darius_daily_report (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id      UUID NOT NULL,
    report_date     DATE NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'DRAFT',

    -- Összesített adatok
    total_buy_huf           NUMERIC(18,2),
    total_sell_huf          NUMERIC(18,2),
    transaction_count       INTEGER,
    total_handling_fee_huf  NUMERIC(18,2),
    branch_count            INTEGER,

    -- Payload
    payload         TEXT,
    payload_format  VARCHAR(10),
    payload_hash    VARCHAR(64),

    -- Beküldés
    submitted_at    TIMESTAMP,
    submitted_by    VARCHAR(100),
    ack_reference   VARCHAR(200),
    ack_at          TIMESTAMP,

    -- Hiba / retry
    error_message   TEXT,
    retry_count     INTEGER NOT NULL DEFAULT 0,
    max_retries     INTEGER NOT NULL DEFAULT 3,
    next_retry_at   TIMESTAMP,

    -- Jóváhagyás (4-eyes)
    approved_by     VARCHAR(100),
    approved_at     TIMESTAMP,

    -- Audit
    created_at      TIMESTAMP DEFAULT now(),
    updated_at      TIMESTAMP DEFAULT now(),
    notes           TEXT,

    CONSTRAINT uk_darius_report_company_date UNIQUE (company_id, report_date),
    CONSTRAINT fk_darius_report_company FOREIGN KEY (company_id) REFERENCES company(id)
);

CREATE INDEX idx_darius_report_company ON darius_daily_report(company_id);
CREATE INDEX idx_darius_report_date ON darius_daily_report(report_date);
CREATE INDEX idx_darius_report_status ON darius_daily_report(status);

CREATE TABLE darius_report_line (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id       UUID NOT NULL,
    branch_id       UUID NOT NULL,
    branch_code     VARCHAR(20),
    currency_code   VARCHAR(3) NOT NULL,

    buy_count               INTEGER DEFAULT 0,
    buy_currency_amount     NUMERIC(18,4) DEFAULT 0,
    buy_huf_amount          NUMERIC(18,2) DEFAULT 0,
    sell_count              INTEGER DEFAULT 0,
    sell_currency_amount    NUMERIC(18,4) DEFAULT 0,
    sell_huf_amount         NUMERIC(18,2) DEFAULT 0,
    avg_buy_rate            NUMERIC(12,4),
    avg_sell_rate           NUMERIC(12,4),
    handling_fee_huf        NUMERIC(18,2) DEFAULT 0,

    CONSTRAINT fk_darius_line_report FOREIGN KEY (report_id) REFERENCES darius_daily_report(id) ON DELETE CASCADE,
    CONSTRAINT fk_darius_line_branch FOREIGN KEY (branch_id) REFERENCES branch(id)
);

CREATE INDEX idx_darius_line_report ON darius_report_line(report_id);
CREATE INDEX idx_darius_line_branch ON darius_report_line(branch_id);
