-- V3_5: Early guard — missing critical tables (fresh install fix)
-- Probléma: V25..V73 migration scriptek olyan táblákat feltételeznek létezőnek
--           amelyeket csak V74 hozna létre. Fresh install esetén ezek hibáznak.
-- Megoldás: Ugyanazokat a táblákat IF NOT EXISTS-szel itt hozzuk létre,
--           MIELŐTT V25..V73 futna. V74 is IF NOT EXISTS-t használ, tehát safe.
-- Szinkron: ha V74 módosul, ezt a fájlt is frissíteni kell!

-- ============================================================
-- 1. audit_log (referenced by V25 ALTER)
-- ============================================================
CREATE TABLE IF NOT EXISTS audit_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action          VARCHAR(50)  NOT NULL,
    entity_type     VARCHAR(50)  NOT NULL,
    entity_id       VARCHAR(50),
    user_id         VARCHAR(50),
    user_name       VARCHAR(100),
    branch_id       VARCHAR(50),
    branch_name     VARCHAR(100),
    changes         TEXT,
    ip_address      VARCHAR(50),
    user_agent      VARCHAR(500),
    old_value       TEXT,
    new_value       TEXT,
    reason          VARCHAR(1000),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_log_entity_type ON audit_log(entity_type);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON audit_log(action);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON audit_log(created_at);

-- ============================================================
-- 2. system_parameter (referenced by V43, V46, V47 INSERTs)
-- ============================================================
CREATE TABLE IF NOT EXISTS system_parameter (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parameter_key   VARCHAR(100) NOT NULL,
    parameter_value TEXT         NOT NULL,
    parameter_type  VARCHAR(30)  NOT NULL DEFAULT 'STRING',
    category        VARCHAR(50)  NOT NULL DEFAULT 'GENERAL',
    description     TEXT,
    is_active       BOOLEAN DEFAULT TRUE,
    updated_at      TIMESTAMP,
    updated_by      VARCHAR(100)
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_system_parameter_key ON system_parameter(parameter_key);

-- ============================================================
-- 3. inventory_movement (referenced by V33 ALTER)
-- ============================================================
CREATE TABLE IF NOT EXISTS inventory_movement (
    id               BIGSERIAL PRIMARY KEY,
    from_branch_id   UUID,
    to_branch_id     UUID,
    currency_id      BIGINT       NOT NULL,
    amount           NUMERIC(18,4) NOT NULL,
    huf_value        NUMERIC(18,2),
    movement_type    VARCHAR(30)  NOT NULL,
    status           VARCHAR(20)  NOT NULL DEFAULT 'PENDING',
    initiated_by_id  BIGINT       NOT NULL,
    approved_by_id   BIGINT,
    received_by_id   BIGINT,
    reference_number VARCHAR(30)  NOT NULL,
    notes            TEXT,
    movement_date    DATE         NOT NULL,
    movement_time    TIME         NOT NULL,
    approved_at      TIMESTAMP,
    received_at      TIMESTAMP,
    created_at       TIMESTAMP    NOT NULL DEFAULT NOW(),

    CONSTRAINT uk_inv_mov_ref_number UNIQUE (reference_number),
    CONSTRAINT fk_inv_mov_from_branch  FOREIGN KEY (from_branch_id)  REFERENCES branch(id),
    CONSTRAINT fk_inv_mov_to_branch    FOREIGN KEY (to_branch_id)    REFERENCES branch(id),
    CONSTRAINT fk_inv_mov_currency     FOREIGN KEY (currency_id)     REFERENCES currency(id),
    CONSTRAINT fk_inv_mov_initiated_by FOREIGN KEY (initiated_by_id) REFERENCES worker(id),
    CONSTRAINT fk_inv_mov_approved_by  FOREIGN KEY (approved_by_id)  REFERENCES worker(id),
    CONSTRAINT fk_inv_mov_received_by  FOREIGN KEY (received_by_id)  REFERENCES worker(id)
);

CREATE INDEX IF NOT EXISTS idx_inv_mov_from_branch ON inventory_movement(from_branch_id);
CREATE INDEX IF NOT EXISTS idx_inv_mov_to_branch ON inventory_movement(to_branch_id);
CREATE INDEX IF NOT EXISTS idx_inv_mov_currency ON inventory_movement(currency_id);
CREATE INDEX IF NOT EXISTS idx_inv_mov_date ON inventory_movement(movement_date);
CREATE INDEX IF NOT EXISTS idx_inv_mov_status ON inventory_movement(status);

-- ============================================================
-- 4. circular (referenced by V48 ALTER)
-- ============================================================
CREATE TABLE IF NOT EXISTS circular (
    id                   BIGSERIAL PRIMARY KEY,
    title                VARCHAR(200) NOT NULL,
    content              TEXT         NOT NULL,
    created_by_id        BIGINT       NOT NULL,
    circular_type        VARCHAR(30)  NOT NULL DEFAULT 'GENERAL',
    target               VARCHAR(30)  NOT NULL DEFAULT 'ALL_BRANCHES',
    priority             VARCHAR(20)  NOT NULL DEFAULT 'NORMAL',
    target_branch_id     UUID,
    target_company_id    INTEGER,
    attachment_filename  VARCHAR(255),
    attachment_mime_type VARCHAR(100),
    attachment_path      VARCHAR(500),
    valid_from           DATE,
    valid_to             DATE,
    registration_number  VARCHAR(50),
    urgent               BOOLEAN      NOT NULL DEFAULT FALSE,
    acknowledged         BOOLEAN      NOT NULL DEFAULT FALSE,
    acknowledged_at      TIMESTAMP,
    created_at           TIMESTAMP    NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_circular_created_by FOREIGN KEY (created_by_id) REFERENCES worker(id)
);

CREATE INDEX IF NOT EXISTS idx_circular_created_by ON circular(created_by_id);

-- ============================================================
-- 5. pos_terminal (referenced by V43 ALTER)
-- ============================================================
CREATE TABLE IF NOT EXISTS pos_terminal (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    terminal_id         VARCHAR(50)  NOT NULL,
    terminal_name       VARCHAR(200),
    terminal_type       VARCHAR(30)  DEFAULT 'MOCK',
    branch_id           UUID         NOT NULL,
    is_active           BOOLEAN      NOT NULL DEFAULT TRUE,
    last_transaction_at TIMESTAMP,
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_pos_terminal_terminal_id ON pos_terminal(terminal_id);

-- ============================================================
-- 6. document (referenced by V73 ALTER)
-- ============================================================
CREATE TABLE IF NOT EXISTS document (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_name      VARCHAR(255) NOT NULL,
    file_type      VARCHAR(100),
    file_size      BIGINT,
    entity_type    VARCHAR(100),
    entity_id      UUID,
    file_data      BYTEA,
    uploaded_at    TIMESTAMP    NOT NULL DEFAULT NOW(),
    uploaded_by_id BIGINT,
    company_id     UUID
);

-- ============================================================
-- 7. own_company (referenced by V62 FK)
-- ============================================================
CREATE TABLE IF NOT EXISTS own_company (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                VARCHAR(200) NOT NULL,
    tax_number          VARCHAR(50),
    registration_number VARCHAR(50),
    address             VARCHAR(500),
    phone               VARCHAR(50),
    email               VARCHAR(100),
    bank_account_number VARCHAR(50),
    iban                VARCHAR(50),
    swift               VARCHAR(20),
    license_number      VARCHAR(100),
    is_active           BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP
);

-- ============================================================
-- 8. fee_discount (referenced by V47 INSERT)
-- ============================================================
CREATE TABLE IF NOT EXISTS fee_discount (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code                   VARCHAR(50)    NOT NULL,
    name                   VARCHAR(200)   NOT NULL,
    discount_type          VARCHAR(50),
    discount_value         NUMERIC(10,4),
    min_transaction_amount NUMERIC(15,2),
    valid_from             DATE,
    valid_to               DATE,
    is_active              BOOLEAN        NOT NULL DEFAULT TRUE,
    created_at             TIMESTAMP      NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_fee_discount_code ON fee_discount(code);

-- ============================================================
-- 9. daily_report
-- ============================================================
CREATE TABLE IF NOT EXISTS daily_report (
    id                BIGSERIAL PRIMARY KEY,
    branch_id         UUID           NOT NULL,
    report_date       DATE           NOT NULL,
    submitted         BOOLEAN        NOT NULL DEFAULT FALSE,
    submitted_at      TIMESTAMP,
    submitted_by_id   BIGINT,
    report_data       TEXT,
    total_buy_huf     NUMERIC(18,2)  DEFAULT 0,
    total_sell_huf    NUMERIC(18,2)  DEFAULT 0,
    total_fee_huf     NUMERIC(18,2)  DEFAULT 0,
    total_profit      NUMERIC(18,2)  DEFAULT 0,
    transaction_count INTEGER        DEFAULT 0,
    created_at        TIMESTAMP      NOT NULL DEFAULT NOW(),

    CONSTRAINT uk_daily_report_branch_date UNIQUE (branch_id, report_date),
    CONSTRAINT fk_daily_report_branch FOREIGN KEY (branch_id) REFERENCES branch(id),
    CONSTRAINT fk_daily_report_submitted_by FOREIGN KEY (submitted_by_id) REFERENCES worker(id)
);

CREATE INDEX IF NOT EXISTS idx_daily_report_branch ON daily_report(branch_id);
CREATE INDEX IF NOT EXISTS idx_daily_report_date ON daily_report(report_date);

-- ============================================================
-- 10. reservation
-- ============================================================
CREATE TABLE IF NOT EXISTS reservation (
    id                          BIGSERIAL PRIMARY KEY,
    company_id                  UUID           NOT NULL,
    customer_id                 BIGINT         NOT NULL,
    branch_id                   UUID           NOT NULL,
    worker_id                   BIGINT         NOT NULL,
    currency_code               VARCHAR(3)     NOT NULL,
    reserved_amount             NUMERIC(15,2)  NOT NULL,
    exchange_rate               NUMERIC(12,4)  NOT NULL,
    deposit_amount              NUMERIC(15,2)  NOT NULL,
    status                      VARCHAR(30)    NOT NULL DEFAULT 'ACTIVE',
    expires_at                  TIMESTAMP      NOT NULL,
    created_at                  TIMESTAMP      NOT NULL DEFAULT NOW(),
    fulfilled_at                TIMESTAMP,
    cancelled_at                TIMESTAMP,
    receipt_number              VARCHAR(50),
    cancellation_receipt_number VARCHAR(50),
    cancellation_reason         VARCHAR(500),
    supervisor_approval         BOOLEAN        DEFAULT FALSE,
    supervisor_worker_id        BIGINT,
    refund_amount               NUMERIC(15,2)  DEFAULT 0,
    notes                       VARCHAR(1000),

    CONSTRAINT fk_reservation_company  FOREIGN KEY (company_id)  REFERENCES company(id),
    CONSTRAINT fk_reservation_customer FOREIGN KEY (customer_id) REFERENCES customer(id),
    CONSTRAINT fk_reservation_branch   FOREIGN KEY (branch_id)   REFERENCES branch(id),
    CONSTRAINT fk_reservation_worker   FOREIGN KEY (worker_id)   REFERENCES worker(id)
);

CREATE INDEX IF NOT EXISTS idx_reservation_customer ON reservation(customer_id);
CREATE INDEX IF NOT EXISTS idx_reservation_branch ON reservation(branch_id);
CREATE INDEX IF NOT EXISTS idx_reservation_status ON reservation(status);
CREATE INDEX IF NOT EXISTS idx_reservation_company ON reservation(company_id);

-- ============================================================
-- 11. storno_approval
-- ============================================================
CREATE TABLE IF NOT EXISTS storno_approval (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id        BIGINT       NOT NULL,
    worker_id             BIGINT       NOT NULL,
    branch_id             UUID         NOT NULL,
    daily_storno_count    INTEGER      NOT NULL,
    approval_status_did   BIGINT,
    request_reason        VARCHAR(500) NOT NULL,
    rejection_reason      VARCHAR(500),
    approved_by_worker_id BIGINT,
    approved_at           TIMESTAMP,
    created_at            TIMESTAMP    NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_storno_approval_transaction FOREIGN KEY (transaction_id) REFERENCES transaction(id),
    CONSTRAINT fk_storno_approval_worker FOREIGN KEY (worker_id) REFERENCES worker(id),
    CONSTRAINT fk_storno_approval_branch FOREIGN KEY (branch_id) REFERENCES branch(id),
    CONSTRAINT fk_storno_approval_approved_by FOREIGN KEY (approved_by_worker_id) REFERENCES worker(id)
);

CREATE INDEX IF NOT EXISTS idx_storno_approval_transaction ON storno_approval(transaction_id);

-- ============================================================
-- 12. branch_group
-- ============================================================
CREATE TABLE IF NOT EXISTS branch_group (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code            VARCHAR(50)  NOT NULL,
    name            VARCHAR(200) NOT NULL,
    description     TEXT,
    group_type_did  BIGINT,
    parent_group_id UUID,
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_branch_group_code ON branch_group(code);

CREATE TABLE IF NOT EXISTS branch_group_branches (
    branch_group_id UUID NOT NULL,
    branch_id       UUID NOT NULL,
    CONSTRAINT fk_bgg_branch_group FOREIGN KEY (branch_group_id) REFERENCES branch_group(id)
);

CREATE INDEX IF NOT EXISTS idx_bgg_branch_group ON branch_group_branches(branch_group_id);

-- ============================================================
-- 13. receipt
-- ============================================================
CREATE TABLE IF NOT EXISTS receipt (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    receipt_number     VARCHAR(50)  NOT NULL,
    transaction_id     UUID,
    receipt_type       VARCHAR(50)  NOT NULL,
    issue_date         DATE         NOT NULL,
    content            TEXT,
    nav_receipt_number VARCHAR(100),
    is_printed         BOOLEAN      NOT NULL DEFAULT FALSE,
    printed_at         TIMESTAMP,
    created_at         TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_receipt_number ON receipt(receipt_number);

-- ============================================================
-- 14. transaction_line
-- ============================================================
CREATE TABLE IF NOT EXISTS transaction_line (
    id              BIGSERIAL PRIMARY KEY,
    transaction_id  BIGINT         NOT NULL,
    line_number     INTEGER        NOT NULL,
    currency_id     BIGINT         NOT NULL,
    applied_rate    NUMERIC(12,4)  NOT NULL,
    original_rate   NUMERIC(12,4),
    settlement_rate NUMERIC(12,4),
    banknote_count  NUMERIC(15,2)  NOT NULL,
    huf_value       NUMERIC(15,0)  NOT NULL,
    line_discount   NUMERIC(15,0)  DEFAULT 0,
    discount_type   INTEGER        DEFAULT 0,

    CONSTRAINT fk_txline_transaction FOREIGN KEY (transaction_id) REFERENCES transaction(id),
    CONSTRAINT fk_txline_currency FOREIGN KEY (currency_id) REFERENCES currency(id)
);

CREATE INDEX IF NOT EXISTS idx_txline_transaction ON transaction_line(transaction_id);
CREATE INDEX IF NOT EXISTS idx_txline_currency ON transaction_line(currency_id);
