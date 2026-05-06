-- E-B8 banki workflow (GitHub issue #279) — első PR (entity + migration)
--
-- Cél: a "banki rendelés" workflow teljes audit-trail-ben tárolása.
-- Lépés-sorrend:
--   1) PENDING — értéktáros / iroda kéri a rendelést (ki, mennyit, milyen valuta)
--   2) APPROVED — ügyvezető jóváhagyja (timestamp + worker_id rögzítve)
--   3) EXECUTED — a bankból megérkezett a pénz, az értéktáros átveszi
--   4) CANCELLED — bármikor (PENDING vagy APPROVED állapotból), indoklással
--
-- Sürgősségi kategória (NORMAL / URGENT / EMERGENCY):
--   - URGENT: ügyfél-foglaláshoz kapcsolódó sürgős igény
--   - EMERGENCY: kritikus készlet-hiány, 1 órán belüli jóváhagyás kell
--
-- 5 éves retention (NGM 23/2014 + AML), de NEM kell archív tábla — a row-ok
-- maradnak. Audit log (transaction_audit_log) a state-változásokhoz.

CREATE TABLE IF NOT EXISTS bank_order (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branch(id),
    currency_id BIGINT NOT NULL REFERENCES currency(id),
    amount NUMERIC(18, 2) NOT NULL CHECK (amount > 0),

    -- Workflow state
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'APPROVED', 'EXECUTED', 'CANCELLED')),
    urgency VARCHAR(20) NOT NULL DEFAULT 'NORMAL'
        CHECK (urgency IN ('NORMAL', 'URGENT', 'EMERGENCY')),

    -- Audit-trail mezők (KI + MIKOR)
    requested_by_worker_id BIGINT NOT NULL REFERENCES worker(id),
    requested_at TIMESTAMP NOT NULL DEFAULT NOW(),
    approved_by_worker_id BIGINT REFERENCES worker(id),
    approved_at TIMESTAMP,
    executed_by_worker_id BIGINT REFERENCES worker(id),
    executed_at TIMESTAMP,
    cancelled_by_worker_id BIGINT REFERENCES worker(id),
    cancelled_at TIMESTAMP,
    cancellation_reason VARCHAR(500),

    -- Optional: bank-side hivatkozási szám (ha a bank visszaad egy ügyletszámot)
    bank_reference VARCHAR(100),

    notes TEXT,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexek a leggyakoribb query-khez
CREATE INDEX IF NOT EXISTS idx_bank_order_branch_status
    ON bank_order(branch_id, status);

CREATE INDEX IF NOT EXISTS idx_bank_order_status_urgency
    ON bank_order(status, urgency);

CREATE INDEX IF NOT EXISTS idx_bank_order_requested_at
    ON bank_order(requested_at DESC);

-- Note: a bank_order Cégkör alá tartozik (multi-tenant) a branch.company_id-n keresztül,
-- ezért NEM kell külön company_id mező — JOIN branch ON branch.id = bank_order.branch_id

-- WU napi keret tábla (10000 USD limit naponta)
-- Forrás: legacy WUNION + 2026-04-29 főértéktáros audit E-B8 javaslat 2.

CREATE TABLE IF NOT EXISTS wu_daily_limit (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES company(id),
    business_date DATE NOT NULL,
    currency_code VARCHAR(3) NOT NULL DEFAULT 'USD',
    daily_limit NUMERIC(18, 2) NOT NULL DEFAULT 10000.00,
    used_amount NUMERIC(18, 2) NOT NULL DEFAULT 0.00,
    reset_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT wu_daily_limit_company_date_currency_uq
        UNIQUE (company_id, business_date, currency_code)
);

CREATE INDEX IF NOT EXISTS idx_wu_daily_limit_company_date
    ON wu_daily_limit(company_id, business_date DESC);

COMMENT ON TABLE bank_order IS
    'E-B8 banki workflow (issue #279). Értéktári banki rendelés audit-trail teljes '
    'PENDING → APPROVED → EXECUTED állapotokkal. NORMAL / URGENT / EMERGENCY '
    'sürgősséggel.';

COMMENT ON TABLE wu_daily_limit IS
    'Western Union napi keret. Cégszintű napi USD limit (default 10000). '
    'Naponta resetelődik (reset_at + új record automatikusan). '
    'A WesternUnionService.checkDailyLimit() ellenőrzi tranzakció előtt.';
