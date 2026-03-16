-- V89: Monthly transaction archive table
-- Legacy: NAPZAR.DLL CopyTables() — havi gyűjtő táblákba másolás
-- Modern: egyetlen archív tábla, yearMonth particionálással

CREATE TABLE IF NOT EXISTS archived_monthly_transaction (
    id                  BIGSERIAL PRIMARY KEY,
    monthly_closing_id  BIGINT NOT NULL,
    branch_id           UUID NOT NULL,
    company_id          UUID NOT NULL,
    original_tx_id      BIGINT,
    transaction_date    DATE NOT NULL,
    transaction_type    VARCHAR(30) NOT NULL,
    currency_code       VARCHAR(3) NOT NULL,
    currency_amount     NUMERIC(18,2) NOT NULL,
    huf_amount          NUMERIC(18,2) NOT NULL,
    exchange_rate       NUMERIC(18,6),
    handling_fee        NUMERIC(18,2),
    customer_id         VARCHAR(50),
    worker_id           BIGINT,
    archived_at         TIMESTAMP NOT NULL DEFAULT now(),
    year_month          VARCHAR(7) NOT NULL
);

CREATE INDEX idx_amt_closing ON archived_monthly_transaction(monthly_closing_id);
CREATE INDEX idx_amt_branch_ym ON archived_monthly_transaction(branch_id, year_month);
