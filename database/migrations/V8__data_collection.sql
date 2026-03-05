-- V8: Adatgyűjtő szerver modul
-- Irodák napi adatainak összegyűjtése a központi DB-be

-- Adatgyűjtés fejléc
CREATE TABLE data_collection (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id         UUID         NOT NULL REFERENCES branch(id),
    collection_date   DATE         NOT NULL,
    status            VARCHAR(20)  NOT NULL DEFAULT 'PENDING',  -- PENDING/COLLECTING/COMPLETED/FAILED
    collection_type   VARCHAR(20)  NOT NULL DEFAULT 'DAILY',    -- DAILY/HOURLY/ON_DEMAND
    transaction_count INTEGER      DEFAULT 0,
    total_buy_huf     NUMERIC(18,2) DEFAULT 0,
    total_sell_huf    NUMERIC(18,2) DEFAULT 0,
    started_at        TIMESTAMP,
    completed_at      TIMESTAMP,
    error_message     VARCHAR(2000),
    created_at        TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP
);

-- Indexek
CREATE INDEX idx_dc_branch_date ON data_collection(branch_id, collection_date);
CREATE INDEX idx_dc_status      ON data_collection(status);
CREATE INDEX idx_dc_type        ON data_collection(collection_type);

-- Egyediség: egy irodához egy típusú gyűjtés egy adott dátumra
CREATE UNIQUE INDEX uq_dc_branch_date_type
    ON data_collection(branch_id, collection_date, collection_type);

-- Összegyűjtött tranzakciók
CREATE TABLE collected_transaction (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data_collection_id      UUID         NOT NULL REFERENCES data_collection(id) ON DELETE CASCADE,
    original_transaction_id BIGINT       NOT NULL,
    transaction_type        VARCHAR(30)  NOT NULL,
    currency_code           VARCHAR(3)   NOT NULL,
    foreign_amount          NUMERIC(15,2) NOT NULL,
    huf_amount              NUMERIC(15,2) NOT NULL,
    rate                    NUMERIC(12,4) NOT NULL,
    receipt_number          VARCHAR(20),
    customer_name           VARCHAR(200),
    transaction_timestamp   TIMESTAMP    NOT NULL
);

CREATE INDEX idx_ct_collection ON collected_transaction(data_collection_id);
CREATE INDEX idx_ct_original   ON collected_transaction(original_transaction_id);
CREATE INDEX idx_ct_currency   ON collected_transaction(currency_code);

-- Összegyűjtött készletek
CREATE TABLE collected_inventory (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data_collection_id    UUID         NOT NULL REFERENCES data_collection(id) ON DELETE CASCADE,
    currency_code         VARCHAR(3)   NOT NULL,
    amount                NUMERIC(15,2) NOT NULL,
    huf_value             NUMERIC(18,2) DEFAULT 0,
    denomination_details  TEXT  -- JSON
);

CREATE INDEX idx_ci_collection ON collected_inventory(data_collection_id);
CREATE INDEX idx_ci_currency   ON collected_inventory(currency_code);
