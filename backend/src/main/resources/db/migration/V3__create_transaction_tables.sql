-- ============================================
-- Phase 3: Core Transaction System
-- Currency, Exchange Rates, Transactions, etc.
-- Multi-tenant support: company_id in ALL tables!
-- ============================================

-- ============================================
-- 1. CURRENCY - Valutanemek
-- ============================================
CREATE TABLE currency (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(3) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10),
    decimal_places INTEGER NOT NULL DEFAULT 2,
    active BOOLEAN NOT NULL DEFAULT true,
    default_buy_spread DECIMAL(5,2) DEFAULT 0,
    default_sell_spread DECIMAL(5,2) DEFAULT 0,
    min_transaction_amount DECIMAL(15,2),
    max_transaction_amount DECIMAL(15,2),
    display_order INTEGER DEFAULT 100,
    flag_icon VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Alap valuták betöltése (27 valuta a legacy rendszerből)
INSERT INTO currency (code, name, symbol, decimal_places, display_order) VALUES
    ('HUF', 'Magyar forint', 'Ft', 0, 1),
    ('EUR', 'Euró', '€', 2, 2),
    ('USD', 'Amerikai dollár', '$', 2, 3),
    ('GBP', 'Brit font', '£', 2, 4),
    ('CHF', 'Svájci frank', 'CHF', 2, 5),
    ('AUD', 'Ausztrál dollár', 'A$', 2, 10),
    ('BAM', 'Bosnyák konvertibilis márka', 'KM', 2, 11),
    ('BGN', 'Bolgár leva', 'лв', 2, 12),
    ('BRL', 'Brazil real', 'R$', 2, 13),
    ('CAD', 'Kanadai dollár', 'C$', 2, 14),
    ('CNY', 'Kínai jüan', '¥', 2, 15),
    ('CZK', 'Cseh korona', 'Kč', 2, 16),
    ('DKK', 'Dán korona', 'kr', 2, 17),
    ('HRK', 'Horvát kuna', 'kn', 2, 18),
    ('ILS', 'Izraeli sékel', '₪', 2, 19),
    ('JPY', 'Japán jen', '¥', 0, 20),
    ('MXN', 'Mexikói peso', '$', 2, 21),
    ('NOK', 'Norvég korona', 'kr', 2, 22),
    ('NZD', 'Új-zélandi dollár', 'NZ$', 2, 23),
    ('PLN', 'Lengyel zloty', 'zł', 2, 24),
    ('RON', 'Román lej', 'lei', 2, 25),
    ('RSD', 'Szerb dinár', 'дин', 2, 26),
    ('RUB', 'Orosz rubel', '₽', 2, 27),
    ('SEK', 'Svéd korona', 'kr', 2, 28),
    ('THB', 'Thai baht', '฿', 2, 29),
    ('TRY', 'Török líra', '₺', 2, 30),
    ('UAH', 'Ukrán hrivnya', '₴', 2, 31);

CREATE INDEX idx_currency_code ON currency(code);
CREATE INDEX idx_currency_active ON currency(active);

-- ============================================
-- 2. EXCHANGE_RATE - Árfolyamok
-- ============================================
CREATE TABLE exchange_rate (
    id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branch(id) ON DELETE SET NULL,
    currency_id BIGINT NOT NULL REFERENCES currency(id) ON DELETE RESTRICT,
    valid_date DATE NOT NULL,
    valid_time TIME NOT NULL,

    -- Alap árfolyamok
    base_buy_rate DECIMAL(12,4) NOT NULL,
    base_sell_rate DECIMAL(12,4) NOT NULL,

    -- Limit 1 árfolyamok
    limit1_amount DECIMAL(15,2),
    limit1_buy_rate DECIMAL(12,4),
    limit1_sell_rate DECIMAL(12,4),

    -- Limit 2 árfolyamok
    limit2_amount DECIMAL(15,2),
    limit2_buy_rate DECIMAL(12,4),
    limit2_sell_rate DECIMAL(12,4),

    -- Limit 3 árfolyamok
    limit3_amount DECIMAL(15,2),
    limit3_buy_rate DECIMAL(12,4),
    limit3_sell_rate DECIMAL(12,4),

    -- Hivatalos árfolyam
    official_rate DECIMAL(12,4),

    active BOOLEAN NOT NULL DEFAULT true,
    created_by VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_exchange_rate_date ON exchange_rate(valid_date, valid_time);
CREATE INDEX idx_exchange_rate_currency ON exchange_rate(currency_id);
CREATE INDEX idx_exchange_rate_company ON exchange_rate(company_id);

-- ============================================
-- 3. CUSTOMER - Ügyfelek
-- ============================================
CREATE TABLE customer (
    id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    customer_code VARCHAR(50),
    name VARCHAR(200) NOT NULL,
    birth_name VARCHAR(200),
    mother_name VARCHAR(200),
    birth_date DATE,
    birth_place VARCHAR(100),
    nationality VARCHAR(3),
    document_number VARCHAR(50),
    document_type VARCHAR(30),
    document_expiry DATE,
    address VARCHAR(500),
    postal_code VARCHAR(10),
    city VARCHAR(100),
    country VARCHAR(3),
    phone VARCHAR(30),
    email VARCHAR(100),
    is_company BOOLEAN DEFAULT false,
    company_name VARCHAR(200),
    tax_number VARCHAR(20),
    registration_number VARCHAR(50),
    active BOOLEAN NOT NULL DEFAULT true,
    is_vip BOOLEAN DEFAULT false,
    notes TEXT,
    last_transaction_date DATE,
    transaction_count INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_customer_company ON customer(company_id);
CREATE INDEX idx_customer_document ON customer(document_number);
CREATE INDEX idx_customer_name ON customer(name);

-- ============================================
-- 4. DAILY_SESSION - Napi munkamenetek
-- ============================================
CREATE TABLE daily_session (
    id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branch(id) ON DELETE RESTRICT,
    session_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',

    -- Nyitás
    opened_by_worker_id BIGINT REFERENCES worker(id),
    opened_at TIMESTAMP,
    opening_balance_huf DECIMAL(15,2) DEFAULT 0,

    -- Zárás
    closed_by_worker_id BIGINT REFERENCES worker(id),
    closed_at TIMESTAMP,
    closing_balance_huf DECIMAL(15,2),
    denomination_verified BOOLEAN DEFAULT false,

    -- Statisztikák
    transaction_count INTEGER DEFAULT 0,
    buy_count INTEGER DEFAULT 0,
    sell_count INTEGER DEFAULT 0,
    reversal_count INTEGER DEFAULT 0,
    buy_turnover_huf DECIMAL(15,2) DEFAULT 0,
    sell_turnover_huf DECIMAL(15,2) DEFAULT 0,
    handling_fee_total DECIMAL(15,2) DEFAULT 0,

    notes TEXT,
    qr_code_generated BOOLEAN DEFAULT false,
    nav_uploaded BOOLEAN DEFAULT false,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_daily_session UNIQUE (branch_id, session_date)
);

CREATE INDEX idx_daily_session_date ON daily_session(session_date);
CREATE INDEX idx_daily_session_branch ON daily_session(branch_id);
CREATE INDEX idx_daily_session_status ON daily_session(status);

-- ============================================
-- 5. TRANSACTION - Tranzakciók (Bizonylatok)
-- ============================================
CREATE TABLE transaction (
    id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branch(id) ON DELETE RESTRICT,
    worker_id BIGINT NOT NULL REFERENCES worker(id) ON DELETE RESTRICT,
    receipt_number VARCHAR(20) NOT NULL,
    transaction_type VARCHAR(30) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'COMPLETED',
    transaction_date DATE NOT NULL,
    transaction_time TIME NOT NULL,

    -- Valuta adatok
    currency_id BIGINT NOT NULL REFERENCES currency(id) ON DELETE RESTRICT,
    currency_amount DECIMAL(15,2) NOT NULL,
    exchange_rate DECIMAL(12,4) NOT NULL,
    huf_amount DECIMAL(15,2) NOT NULL,

    -- Díjak
    handling_fee DECIMAL(15,2) DEFAULT 0,
    discount_amount DECIMAL(15,2) DEFAULT 0,
    discount_percent DECIMAL(5,2) DEFAULT 0,

    -- Ügyfél
    customer_id VARCHAR(50),
    customer_name VARCHAR(200),
    customer_address VARCHAR(500),
    customer_document_number VARCHAR(50),
    customer_nationality VARCHAR(3),

    -- Sztornó
    original_transaction_id BIGINT REFERENCES transaction(id),
    reversal_reason VARCHAR(500),
    approved_by VARCHAR(100),

    -- Egyéb
    notes TEXT,
    printed BOOLEAN DEFAULT false,
    mtcn VARCHAR(50),
    reference_number VARCHAR(100),

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_transaction_date ON transaction(transaction_date);
CREATE INDEX idx_transaction_branch ON transaction(branch_id);
CREATE INDEX idx_transaction_worker ON transaction(worker_id);
CREATE INDEX idx_transaction_receipt ON transaction(receipt_number);
CREATE INDEX idx_transaction_company ON transaction(company_id);
CREATE INDEX idx_transaction_type ON transaction(transaction_type);
CREATE INDEX idx_transaction_status ON transaction(status);

-- ============================================
-- 6. CASH_BALANCE - Kassza egyenlegek
-- ============================================
CREATE TABLE cash_balance (
    id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branch(id) ON DELETE RESTRICT,
    currency_id BIGINT NOT NULL REFERENCES currency(id) ON DELETE RESTRICT,
    current_balance DECIMAL(15,2) NOT NULL DEFAULT 0,
    opening_balance DECIMAL(15,2) DEFAULT 0,
    min_balance DECIMAL(15,2),
    max_balance DECIMAL(15,2),
    last_transaction_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_cash_balance UNIQUE (branch_id, currency_id)
);

CREATE INDEX idx_cash_balance_branch ON cash_balance(branch_id);
CREATE INDEX idx_cash_balance_currency ON cash_balance(currency_id);

-- ============================================
-- 7. DENOMINATION - Címletek
-- ============================================
CREATE TABLE denomination (
    id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branch(id) ON DELETE RESTRICT,
    currency_id BIGINT NOT NULL REFERENCES currency(id) ON DELETE RESTRICT,
    face_value DECIMAL(15,2) NOT NULL,
    denomination_type VARCHAR(20) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0,
    min_quantity INTEGER DEFAULT 0,
    max_quantity INTEGER,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_denomination_branch ON denomination(branch_id);
CREATE INDEX idx_denomination_currency ON denomination(currency_id);

-- ============================================
-- 8. EXCHANGE_RATE_HISTORY - Árfolyam történet
-- ============================================
CREATE TABLE exchange_rate_history (
    id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    currency_id BIGINT NOT NULL REFERENCES currency(id) ON DELETE RESTRICT,
    valid_date DATE NOT NULL,
    valid_time TIME NOT NULL,
    base_buy_rate DECIMAL(12,4) NOT NULL,
    base_sell_rate DECIMAL(12,4) NOT NULL,
    official_rate DECIMAL(12,4),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_rate_history_date ON exchange_rate_history(valid_date);
CREATE INDEX idx_rate_history_currency ON exchange_rate_history(currency_id);

-- ============================================
-- COMMENTS
-- ============================================
COMMENT ON TABLE currency IS 'Valutanemek - 27 valuta támogatás';
COMMENT ON TABLE exchange_rate IS 'Árfolyamok - limit szintű árfolyamokkal';
COMMENT ON TABLE customer IS 'Ügyfelek - adóhatósági azonosításhoz';
COMMENT ON TABLE daily_session IS 'Napi munkamenetek - nyitás/zárás';
COMMENT ON TABLE transaction IS 'Tranzakciók (bizonylatok) - vétel/eladás/sztornó';
COMMENT ON TABLE cash_balance IS 'Kassza egyenlegek valutánként';
COMMENT ON TABLE denomination IS 'Címletek készletkezelése';
COMMENT ON TABLE exchange_rate_history IS 'Árfolyam történet archiváláshoz';
