-- V4: Hiányzó táblák a Delphi Firebird rendszerből
-- A 203 Firebird tábla közül ezek nem voltak még konvertálva
-- Generálta: Junior csapat, 2026-03-05

-- ============================================
-- PHASE 1: PÉNZTÁR CORE
-- ============================================

-- Bizonylat szekvenciák (UTOLSOBLOKKOK helyett)
CREATE SEQUENCE IF NOT EXISTS seq_receipt_sell START WITH 1;
CREATE SEQUENCE IF NOT EXISTS seq_receipt_buy START WITH 1;
CREATE SEQUENCE IF NOT EXISTS seq_receipt_transfer START WITH 1;
CREATE SEQUENCE IF NOT EXISTS seq_receipt_storno START WITH 1;
CREATE SEQUENCE IF NOT EXISTS seq_receipt_wu START WITH 1;
CREATE SEQUENCE IF NOT EXISTS seq_receipt_fee START WITH 1;

-- QR paraméterek (NAV adóhatósági QR-kód)
CREATE TABLE IF NOT EXISTS qr_parameters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branch(id),
    tax_number VARCHAR(20) NOT NULL,
    software_id VARCHAR(50) NOT NULL DEFAULT 'VALUTA-EBC-2026',
    software_version VARCHAR(20) NOT NULL DEFAULT '2.0.0',
    nav_technical_user VARCHAR(50),
    nav_technical_password VARCHAR(255),
    nav_signature_key VARCHAR(255),
    nav_exchange_key VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

-- ============================================
-- PHASE 2: ÉRTÉKTÁR / SZERVER SZINKRONIZÁCIÓ
-- ============================================

-- Szinkronizációs sor (FORGALOMGYUJTO + CIMLETGYUJTO + összes gyűjtő)
CREATE TABLE IF NOT EXISTS sync_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branch(id),
    sync_type VARCHAR(50) NOT NULL, -- 'turnover', 'denomination', 'storno', 'bank_flow', 'wu'
    payload JSONB NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- PENDING, SENT, CONFIRMED, FAILED
    attempt_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP,
    confirmed_at TIMESTAMP,
    error_message TEXT
);

CREATE INDEX idx_sync_queue_status ON sync_queue(status);
CREATE INDEX idx_sync_queue_branch ON sync_queue(branch_id);

-- Bank pénztári napló (HRKNAPLO)
CREATE TABLE IF NOT EXISTS bank_cash_journal (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branch(id),
    journal_date DATE NOT NULL,
    entry_type VARCHAR(20) NOT NULL, -- 'DEPOSIT', 'WITHDRAWAL', 'INVOICE_PAYMENT'
    bank_name VARCHAR(100),
    bank_account VARCHAR(50),
    currency_id UUID NOT NULL REFERENCES currency(id),
    amount DECIMAL(18,2) NOT NULL,
    huf_amount DECIMAL(18,2),
    invoice_number VARCHAR(50),
    description TEXT,
    receipt_number VARCHAR(50),
    worker_id UUID REFERENCES worker(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dekád jelentés (DEKADJELENTES)
CREATE TABLE IF NOT EXISTS decade_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branch(id),
    decade_start DATE NOT NULL,
    decade_end DATE NOT NULL,
    report_data JSONB NOT NULL, -- teljes dekád összesítő
    printed_at TIMESTAMP,
    printed_by UUID REFERENCES worker(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Matrica bizonylat (MATBIZONYLAT)
CREATE TABLE IF NOT EXISTS stamp_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branch(id),
    receipt_number VARCHAR(50) NOT NULL,
    receipt_date DATE NOT NULL,
    stamp_type VARCHAR(20) NOT NULL, -- 'PURCHASE', 'SALE', 'RETURN'
    total_amount DECIMAL(18,2) NOT NULL,
    worker_id UUID REFERENCES worker(id),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Matrica adat (MATDATA)
CREATE TABLE IF NOT EXISTS stamp_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stamp_receipt_id UUID NOT NULL REFERENCES stamp_receipts(id),
    stamp_serial VARCHAR(50) NOT NULL,
    denomination DECIMAL(18,2) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, USED, CANCELLED
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- PHASE 3: WESTERN UNION MODUL
-- ============================================

-- WU készletek (WUAFAADATOK)
CREATE TABLE IF NOT EXISTS wu_balances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branch(id),
    usd_balance DECIMAL(18,2) NOT NULL DEFAULT 0,
    huf_balance DECIMAL(18,2) NOT NULL DEFAULT 0,
    last_receipt_sell VARCHAR(50), -- utolsó WB- bizonylat
    last_receipt_buy VARCHAR(50), -- utolsó WK- bizonylat
    last_receipt_customer_in VARCHAR(50), -- utolsó UB- bizonylat
    last_receipt_customer_out VARCHAR(50), -- utolsó UK- bizonylat
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(branch_id)
);

-- WU ügyfelek (WUGYFEL)
CREATE TABLE IF NOT EXISTS wu_customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customer(id),
    wu_customer_code VARCHAR(50),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(50),
    id_type VARCHAR(50),
    id_number VARCHAR(50),
    nationality VARCHAR(50),
    date_of_birth DATE,
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

-- WU tranzakciók (WUMOZGAS)
CREATE TABLE IF NOT EXISTS wu_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branch(id),
    wu_customer_id UUID REFERENCES wu_customers(id),
    transaction_type VARCHAR(10) NOT NULL, -- 'SEND', 'RECEIVE'
    mtcn VARCHAR(20), -- Money Transfer Control Number
    amount_usd DECIMAL(18,2),
    amount_huf DECIMAL(18,2),
    exchange_rate DECIMAL(18,6),
    fee_amount DECIMAL(18,2),
    sender_name VARCHAR(200),
    receiver_name VARCHAR(200),
    destination_country VARCHAR(100),
    receipt_number VARCHAR(50),
    status VARCHAR(20) NOT NULL DEFAULT 'COMPLETED',
    worker_id UUID REFERENCES worker(id),
    transaction_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- INDEXEK
-- ============================================

CREATE INDEX idx_wu_transactions_branch ON wu_transactions(branch_id);
CREATE INDEX idx_wu_transactions_date ON wu_transactions(transaction_date);
CREATE INDEX idx_wu_transactions_mtcn ON wu_transactions(mtcn);
CREATE INDEX idx_bank_cash_journal_branch ON bank_cash_journal(branch_id);
CREATE INDEX idx_bank_cash_journal_date ON bank_cash_journal(journal_date);
CREATE INDEX idx_stamp_receipts_branch ON stamp_receipts(branch_id);
CREATE INDEX idx_qr_parameters_branch ON qr_parameters(branch_id);
