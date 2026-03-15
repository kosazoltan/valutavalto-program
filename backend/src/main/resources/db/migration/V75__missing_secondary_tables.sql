-- V75: Missing secondary tables — entities that exist in Java but had no CREATE TABLE migration
-- Previously created by Hibernate ddl-auto=update, now explicit.
-- All use IF NOT EXISTS for idempotency on existing databases.

-- ============================================================
-- 1. anonymous_report
-- ============================================================
CREATE TABLE IF NOT EXISTS anonymous_report (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_type    VARCHAR(50)  NOT NULL,
    subject        VARCHAR(200) NOT NULL,
    description    TEXT,
    reported_at    TIMESTAMP    NOT NULL DEFAULT NOW(),
    status         VARCHAR(20)  NOT NULL DEFAULT 'NEW',
    assigned_to_id BIGINT,
    resolution     TEXT
);

-- ============================================================
-- 2. archive_task
-- ============================================================
CREATE TABLE IF NOT EXISTS archive_task (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_type        VARCHAR(100) NOT NULL,
    entity_type      VARCHAR(100) NOT NULL,
    criteria         TEXT,
    status           VARCHAR(20)  NOT NULL DEFAULT 'PENDING',
    started_at       TIMESTAMP,
    completed_at     TIMESTAMP,
    archive_location VARCHAR(500)
);

-- ============================================================
-- 3. authorization_log
-- ============================================================
CREATE TABLE IF NOT EXISTS authorization_log (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    representative_id      UUID         NOT NULL,
    action                 VARCHAR(100) NOT NULL,
    transaction_id         BIGINT,
    performed_at           TIMESTAMP    NOT NULL DEFAULT NOW(),
    performed_by_worker_id BIGINT       NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_auth_log_representative ON authorization_log(representative_id);

-- ============================================================
-- 4. authorized_representative
-- ============================================================
CREATE TABLE IF NOT EXISTS authorized_representative (
    id                              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id                     BIGINT       NOT NULL,
    representative_name             VARCHAR(200) NOT NULL,
    representative_document_number  VARCHAR(50)  NOT NULL,
    representative_document_type    VARCHAR(50)  NOT NULL,
    authorization_start             DATE         NOT NULL,
    authorization_end               DATE,
    is_active                       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at                      TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_auth_rep_customer ON authorized_representative(customer_id);

-- ============================================================
-- 5. cash_desk_break
-- ============================================================
CREATE TABLE IF NOT EXISTS cash_desk_break (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cash_desk_id UUID         NOT NULL,
    break_start  TIMESTAMP    NOT NULL,
    break_end    TIMESTAMP,
    break_type   VARCHAR(50)  NOT NULL,
    reason       VARCHAR(500),
    is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cash_desk_break_desk ON cash_desk_break(cash_desk_id);

-- ============================================================
-- 6. closing_wizard
-- ============================================================
CREATE TABLE IF NOT EXISTS closing_wizard (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id               UUID         NOT NULL,
    cash_desk_id            UUID,
    closing_date            DATE         NOT NULL,
    closing_type            VARCHAR(20)  NOT NULL,
    current_step            INTEGER      NOT NULL DEFAULT 1,
    total_steps             INTEGER      NOT NULL DEFAULT 5,
    wizard_status           VARCHAR(20)  NOT NULL DEFAULT 'IN_PROGRESS',
    started_by_worker_id    BIGINT       NOT NULL,
    started_at              TIMESTAMP    NOT NULL,
    completed_by_worker_id  BIGINT,
    completed_at            TIMESTAMP,
    notes                   VARCHAR(1000),

    CONSTRAINT fk_closing_wizard_branch FOREIGN KEY (branch_id) REFERENCES branch(id),
    CONSTRAINT fk_closing_wizard_started_by FOREIGN KEY (started_by_worker_id) REFERENCES worker(id)
);

CREATE INDEX IF NOT EXISTS idx_closing_wizard_branch ON closing_wizard(branch_id);

-- ============================================================
-- 7. closing_wizard_step
-- ============================================================
CREATE TABLE IF NOT EXISTS closing_wizard_step (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wizard_id        UUID         NOT NULL,
    step_number      INTEGER      NOT NULL,
    step_title       VARCHAR(200) NOT NULL,
    step_description VARCHAR(1000),
    completed        BOOLEAN      NOT NULL DEFAULT FALSE,
    can_proceed      BOOLEAN      NOT NULL DEFAULT TRUE,
    step_data        TEXT,

    CONSTRAINT fk_closing_wizard_step_wizard FOREIGN KEY (wizard_id) REFERENCES closing_wizard(id)
);

CREATE INDEX IF NOT EXISTS idx_closing_wizard_step_wizard ON closing_wizard_step(wizard_id);

-- ============================================================
-- 8. commission_rate
-- ============================================================
CREATE TABLE IF NOT EXISTS commission_rate (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR(50)   NOT NULL,
    entity_id   UUID,
    currency_id BIGINT,
    rate        NUMERIC(10,4) NOT NULL,
    valid_from  DATE          NOT NULL,
    valid_to    DATE,
    is_active   BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP     NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP
);

-- ============================================================
-- 9. competitor
-- ============================================================
CREATE TABLE IF NOT EXISTS competitor (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       VARCHAR(200) NOT NULL,
    website    VARCHAR(500),
    branch_id  UUID,
    is_active  BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);

-- ============================================================
-- 10. competitor_rates
-- ============================================================
CREATE TABLE IF NOT EXISTS competitor_rates (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    competitor_id UUID           NOT NULL,
    currency_id   BIGINT         NOT NULL,
    buy_rate      NUMERIC(18,6),
    sell_rate     NUMERIC(18,6),
    rate_date     DATE           NOT NULL,
    source        VARCHAR(100),
    created_by    BIGINT,
    created_at    TIMESTAMP      NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_comp_rate_competitor FOREIGN KEY (competitor_id) REFERENCES competitor(id),
    CONSTRAINT fk_comp_rate_currency FOREIGN KEY (currency_id) REFERENCES currency(id)
);

CREATE INDEX IF NOT EXISTS idx_competitor_rate_comp ON competitor_rates(competitor_id);

-- ============================================================
-- 11. contribution
-- ============================================================
CREATE TABLE IF NOT EXISTS contribution (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contribution_type VARCHAR(50)   NOT NULL,
    branch_id         UUID          NOT NULL,
    currency_id       BIGINT,
    amount            NUMERIC(18,2) NOT NULL,
    period_start      DATE          NOT NULL,
    period_end        DATE          NOT NULL,
    status            VARCHAR(30)   NOT NULL DEFAULT 'CALCULATED',
    calculated_at     TIMESTAMP,
    created_at        TIMESTAMP     NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP
);

-- ============================================================
-- 12. currency_group
-- ============================================================
CREATE TABLE IF NOT EXISTS currency_group (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code         VARCHAR(20)  NOT NULL,
    name         VARCHAR(200) NOT NULL,
    description  TEXT,
    currency_ids TEXT,
    is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_currency_group_code ON currency_group(code);

-- ============================================================
-- 13. denomination_balance
-- ============================================================
CREATE TABLE IF NOT EXISTS denomination_balance (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cash_desk_id    UUID          NOT NULL,
    denomination_id BIGINT        NOT NULL,
    quantity        INTEGER       NOT NULL DEFAULT 0,
    total_value     NUMERIC(15,2) NOT NULL DEFAULT 0,
    updated_at      TIMESTAMP,

    CONSTRAINT uk_denom_balance_desk_denom UNIQUE (cash_desk_id, denomination_id),
    CONSTRAINT fk_denom_balance_denomination FOREIGN KEY (denomination_id) REFERENCES denomination(id)
);

CREATE INDEX IF NOT EXISTS idx_denom_balance_desk ON denomination_balance(cash_desk_id);

-- ============================================================
-- 14. exchange_rate_display
-- ============================================================
CREATE TABLE IF NOT EXISTS exchange_rate_display (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    display_name     VARCHAR(200) NOT NULL,
    currency_ids     TEXT,
    refresh_interval INTEGER      NOT NULL DEFAULT 60,
    is_active        BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMP
);

-- ============================================================
-- 15. exchange_rate_source
-- ============================================================
CREATE TABLE IF NOT EXISTS exchange_rate_source (
    id                       BIGSERIAL PRIMARY KEY,
    source_name              VARCHAR(50)  NOT NULL,
    source_url               VARCHAR(500),
    polling_interval_minutes INTEGER,
    is_active                BOOLEAN      NOT NULL DEFAULT TRUE,
    last_success_at          TIMESTAMP,
    last_polled_at           TIMESTAMP,
    last_error_at            TIMESTAMP,
    last_error               VARCHAR(1000),
    success_count            BIGINT       DEFAULT 0,
    error_count              BIGINT       DEFAULT 0,
    created_at               TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMP
);

-- ============================================================
-- 16. fee_rate
-- ============================================================
CREATE TABLE IF NOT EXISTS fee_rate (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fee_type_id  UUID          NOT NULL,
    currency_id  BIGINT,
    branch_id    UUID,
    min_amount   NUMERIC(15,2),
    max_amount   NUMERIC(15,2),
    rate         NUMERIC(10,4),
    fixed_amount NUMERIC(15,2),
    valid_from   DATE,
    valid_to     DATE,
    is_active    BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP     NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP
);

-- ============================================================
-- 17. fee_type
-- ============================================================
CREATE TABLE IF NOT EXISTS fee_type (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code               VARCHAR(50)  NOT NULL,
    name               VARCHAR(200) NOT NULL,
    description        TEXT,
    calculation_method VARCHAR(50),
    is_active          BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at         TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_fee_type_code ON fee_type(code);

-- ============================================================
-- 18. handling_fee_bracket
-- ============================================================
CREATE TABLE IF NOT EXISTS handling_fee_bracket (
    id            BIGSERIAL PRIMARY KEY,
    company_id    UUID          NOT NULL,
    bracket_order INTEGER       NOT NULL,
    upper_limit   NUMERIC(15,0) NOT NULL,
    fee_amount    NUMERIC(15,0) NOT NULL,
    active        BOOLEAN       NOT NULL DEFAULT TRUE,

    CONSTRAINT fk_fee_bracket_company FOREIGN KEY (company_id) REFERENCES company(id)
);

CREATE INDEX IF NOT EXISTS idx_fee_bracket_company ON handling_fee_bracket(company_id);

-- ============================================================
-- 19. handover_sheet
-- ============================================================
CREATE TABLE IF NOT EXISTS handover_sheet (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sheet_number      VARCHAR(50) NOT NULL,
    from_cash_desk_id UUID        NOT NULL,
    to_cash_desk_id   UUID        NOT NULL,
    transfer_date     DATE        NOT NULL,
    amounts           TEXT,
    notes             TEXT,
    status            VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    created_by_id     BIGINT,
    created_at        TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_handover_sheet_number ON handover_sheet(sheet_number);

-- ============================================================
-- 20. initial_fee_config
-- ============================================================
CREATE TABLE IF NOT EXISTS initial_fee_config (
    id                     BIGSERIAL PRIMARY KEY,
    company_id             UUID          NOT NULL,
    fee_name               VARCHAR(100)  NOT NULL,
    fee_amount             NUMERIC(10,0) NOT NULL,
    min_transaction_amount NUMERIC(15,0),
    max_fee_amount         NUMERIC(10,0),
    daily_discount_limit   INTEGER       DEFAULT 5,
    daily_custom_fee_limit INTEGER       DEFAULT 3,
    active                 BOOLEAN       NOT NULL DEFAULT TRUE,

    CONSTRAINT fk_initfee_company FOREIGN KEY (company_id) REFERENCES company(id)
);

-- ============================================================
-- 21. inventory_summary
-- ============================================================
CREATE TABLE IF NOT EXISTS inventory_summary (
    id                  BIGSERIAL PRIMARY KEY,
    branch_id           UUID           NOT NULL,
    currency_id         BIGINT         NOT NULL,
    current_stock       NUMERIC(18,4)  NOT NULL DEFAULT 0,
    daily_buy_total     NUMERIC(18,2)  DEFAULT 0,
    daily_sell_total    NUMERIC(18,2)  DEFAULT 0,
    daily_fee_total     NUMERIC(18,2)  DEFAULT 0,
    bank_withdraw_total NUMERIC(18,2)  DEFAULT 0,
    bank_deposit_total  NUMERIC(18,2)  DEFAULT 0,
    summary_date        DATE           NOT NULL,
    last_updated        TIME,
    created_at          TIMESTAMP      NOT NULL DEFAULT NOW(),

    CONSTRAINT uk_inv_sum_branch_currency_date UNIQUE (branch_id, currency_id, summary_date),
    CONSTRAINT fk_inv_sum_branch FOREIGN KEY (branch_id) REFERENCES branch(id),
    CONSTRAINT fk_inv_sum_currency FOREIGN KEY (currency_id) REFERENCES currency(id)
);

-- ============================================================
-- 22. notification
-- ============================================================
CREATE TABLE IF NOT EXISTS notification (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title      VARCHAR(200) NOT NULL,
    message    TEXT         NOT NULL,
    type       VARCHAR(30)  NOT NULL,
    user_id    VARCHAR(50),
    is_read    BOOLEAN      DEFAULT FALSE,
    created_at TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 23. organization
-- ============================================================
CREATE TABLE IF NOT EXISTS organization (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code                  VARCHAR(50)  NOT NULL,
    name                  VARCHAR(200) NOT NULL,
    description           TEXT,
    parent_id             UUID,
    organization_type_did BIGINT,
    is_active             BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at            TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_organization_code ON organization(code);

-- ============================================================
-- 24. organizational_system_parameter
-- ============================================================
CREATE TABLE IF NOT EXISTS organizational_system_parameter (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID         NOT NULL,
    parameter_key   VARCHAR(100) NOT NULL,
    parameter_value TEXT         NOT NULL,
    currency_id     BIGINT,
    valid_from      DATE         NOT NULL,
    valid_to        DATE,
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP
);

-- ============================================================
-- 25. prohibited_company
-- ============================================================
CREATE TABLE IF NOT EXISTS prohibited_company (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name        VARCHAR(300) NOT NULL,
    tax_number          VARCHAR(50),
    registration_number VARCHAR(50),
    list_type           VARCHAR(50),
    list_source         VARCHAR(200),
    reason              TEXT,
    is_active           BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP
);

-- ============================================================
-- 26. prohibited_person
-- ============================================================
CREATE TABLE IF NOT EXISTS prohibited_person (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name       VARCHAR(300) NOT NULL,
    document_number VARCHAR(50),
    identity_number VARCHAR(50),
    passport_number VARCHAR(50),
    date_of_birth   DATE,
    nationality     VARCHAR(100),
    list_type       VARCHAR(50),
    list_source     VARCHAR(200),
    reason          TEXT,
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP
);

-- ============================================================
-- 27. shipment_request
-- ============================================================
CREATE TABLE IF NOT EXISTS shipment_request (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_number  VARCHAR(50)  NOT NULL,
    from_branch_id  UUID         NOT NULL,
    to_branch_id    UUID         NOT NULL,
    requested_by_id BIGINT       NOT NULL,
    status          VARCHAR(20)  NOT NULL DEFAULT 'DRAFT',
    request_date    DATE         NOT NULL,
    delivery_date   DATE,
    notes           TEXT,
    created_at      TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_shipment_request_number ON shipment_request(request_number);

-- ============================================================
-- 28. shipment_request_item
-- ============================================================
CREATE TABLE IF NOT EXISTS shipment_request_item (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shipment_request_id UUID          NOT NULL,
    currency_id         BIGINT        NOT NULL,
    requested_amount    NUMERIC(15,2) NOT NULL,
    approved_amount     NUMERIC(15,2),
    delivered_amount    NUMERIC(15,2),

    CONSTRAINT fk_ship_item_request FOREIGN KEY (shipment_request_id) REFERENCES shipment_request(id)
);

-- ============================================================
-- 29. worker_commission
-- ============================================================
CREATE TABLE IF NOT EXISTS worker_commission (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_id         BIGINT        NOT NULL,
    branch_id         UUID          NOT NULL,
    period_start      DATE          NOT NULL,
    period_end        DATE          NOT NULL,
    total_sales       NUMERIC(18,2) DEFAULT 0,
    total_buys        NUMERIC(18,2) DEFAULT 0,
    total_fees        NUMERIC(18,2) DEFAULT 0,
    commission_rate   NUMERIC(10,4),
    commission_amount NUMERIC(18,2) DEFAULT 0,
    status            VARCHAR(30)   NOT NULL DEFAULT 'CALCULATED',
    paid_at           TIMESTAMP,
    created_at        TIMESTAMP     NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP
);

-- ============================================================
-- 30. workstation
-- ============================================================
CREATE TABLE IF NOT EXISTS workstation (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code           VARCHAR(50)  NOT NULL,
    name           VARCHAR(200) NOT NULL,
    branch_id      UUID         NOT NULL,
    ip_address     VARCHAR(45),
    mac_address    VARCHAR(17),
    is_active      BOOLEAN      NOT NULL DEFAULT TRUE,
    last_heartbeat TIMESTAMP,
    created_at     TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uk_workstation_code ON workstation(code);
