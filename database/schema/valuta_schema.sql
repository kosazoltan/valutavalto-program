-- Valutaváltó program teljes adatbázis séma
-- Összevonva V1 és V3 migrációkból
-- Csak séma struktúra, adatok nélkül
-- 
-- Generálva: 2025-12-14 19:17:17
-- 

-- V1__create_initial_schema.sql
-- Valutaváltó program adatbázis séma

-- Dictionary tábla a UUID-s típusokhoz
CREATE TABLE IF NOT EXISTS dictionary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    name_hu VARCHAR(255),
    description TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    UNIQUE(category, code)
);

-- Cég tábla (multi-tenant támogatás)
CREATE TABLE IF NOT EXISTS company (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    tax_number VARCHAR(20),
    registration_number VARCHAR(50),
    address TEXT,
    phone VARCHAR(50),
    email VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

-- Fiók tábla
CREATE TABLE IF NOT EXISTS branch (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) NOT NULL,
    company_id UUID NOT NULL REFERENCES company(id),
    bank_code VARCHAR(20) NOT NULL,
    branch_type_did UUID NOT NULL REFERENCES dictionary(id),
    parent_branch_id UUID REFERENCES branch(id),
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    zip_code VARCHAR(10) NOT NULL,
    country_did UUID NOT NULL REFERENCES dictionary(id),
    phone VARCHAR(50),
    email VARCHAR(255),
    branch_status_did UUID NOT NULL REFERENCES dictionary(id),
    opening_date DATE NOT NULL,
    denomination_rule_id UUID,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

-- Dolgozó tábla
CREATE TABLE IF NOT EXISTS worker (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID REFERENCES branch(id),
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    role_did UUID REFERENCES dictionary(id),
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP,
    pin_code VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

-- Valuta tábla
CREATE TABLE IF NOT EXISTS currency (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(3) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10),
    is_base BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    currency_status_did UUID REFERENCES dictionary(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

-- Árfolyam tábla
CREATE TABLE IF NOT EXISTS exchange_rate (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    currency_id UUID NOT NULL REFERENCES currency(id),
    rate_date DATE NOT NULL,
    buy_rate DECIMAL(18, 6) NOT NULL,
    mid_rate DECIMAL(18, 6) NOT NULL,
    sell_rate DECIMAL(18, 6) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    validation_date TIMESTAMP NOT NULL,
    expiration_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

-- Ügyfél tábla
CREATE TABLE IF NOT EXISTS customer (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_type_did UUID REFERENCES dictionary(id),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    birth_date DATE NOT NULL,
    identity_number VARCHAR(50) NOT NULL,
    identity_type_did UUID REFERENCES dictionary(id),
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    zip_code VARCHAR(10) NOT NULL,
    country_did UUID REFERENCES dictionary(id),
    phone VARCHAR(50),
    email VARCHAR(255),
    registration_date DATE NOT NULL,
    nationality_did UUID REFERENCES dictionary(id),
    is_pep BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

-- Tiltólistás személyek
CREATE TABLE IF NOT EXISTS prohibited_person (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(255) NOT NULL,
    birth_date DATE,
    nationality VARCHAR(100),
    passport_number VARCHAR(50),
    identity_number VARCHAR(50),
    address TEXT,
    list_type VARCHAR(50) NOT NULL,
    list_source VARCHAR(100) NOT NULL,
    added_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP,
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

-- Tranzakció tábla
CREATE TABLE IF NOT EXISTS transaction (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_number VARCHAR(50) UNIQUE NOT NULL,
    branch_id UUID NOT NULL REFERENCES branch(id),
    customer_id UUID NOT NULL REFERENCES customer(id),
    worker_id UUID NOT NULL REFERENCES worker(id),
    transaction_type_did UUID NOT NULL REFERENCES dictionary(id),
    source_currency_id UUID NOT NULL REFERENCES currency(id),
    target_currency_id UUID NOT NULL REFERENCES currency(id),
    source_amount DECIMAL(18, 2) NOT NULL,
    target_amount DECIMAL(18, 2) NOT NULL,
    exchange_rate DECIMAL(18, 6) NOT NULL,
    fee_amount DECIMAL(18, 2) DEFAULT 0,
    fee_percentage DECIMAL(5, 4) DEFAULT 0,
    transaction_date TIMESTAMP NOT NULL,
    status_did UUID NOT NULL REFERENCES dictionary(id),
    notes TEXT,
    receipt_number VARCHAR(50),
    is_synced BOOLEAN DEFAULT FALSE,
    synced_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

-- AML ellenőrzés tábla
CREATE TABLE IF NOT EXISTS aml_check (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID REFERENCES transaction(id),
    customer_id UUID NOT NULL REFERENCES customer(id),
    check_date TIMESTAMP NOT NULL,
    check_type_did UUID NOT NULL REFERENCES dictionary(id),
    result_did UUID NOT NULL REFERENCES dictionary(id),
    risk_level_did UUID REFERENCES dictionary(id),
    performed_by UUID NOT NULL REFERENCES worker(id),
    notes TEXT,
    require_approval BOOLEAN NOT NULL DEFAULT FALSE,
    approved_by UUID REFERENCES worker(id),
    approval_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

-- Indexek a gyakori lekérdezésekhez
CREATE INDEX IF NOT EXISTS idx_transaction_branch ON transaction(branch_id);
CREATE INDEX IF NOT EXISTS idx_transaction_customer ON transaction(customer_id);
CREATE INDEX IF NOT EXISTS idx_transaction_date ON transaction(created_at);
CREATE INDEX IF NOT EXISTS idx_transaction_number ON transaction(transaction_number);
CREATE INDEX IF NOT EXISTS idx_exchange_rate_currency ON exchange_rate(currency_id);
CREATE INDEX IF NOT EXISTS idx_exchange_rate_branch ON exchange_rate(branch_id);
CREATE INDEX IF NOT EXISTS idx_exchange_rate_valid ON exchange_rate(valid_from, valid_to);
CREATE INDEX IF NOT EXISTS idx_customer_name ON customer(full_name);
CREATE INDEX IF NOT EXISTS idx_customer_id_number ON customer(id_number);
CREATE INDEX IF NOT EXISTS idx_prohibited_person_name ON prohibited_person(full_name);
CREATE INDEX IF NOT EXISTS idx_aml_check_transaction ON aml_check(transaction_id);
CREATE INDEX IF NOT EXISTS idx_aml_check_customer ON aml_check(customer_id);
CREATE INDEX IF NOT EXISTS idx_worker_username ON worker(username);
CREATE INDEX IF NOT EXISTS idx_worker_branch ON worker(branch_id);


-- ============================================
-- BŐVÍTETT SÉMA (V3)
-- ============================================

-- V3__add_extended_schema.sql
-- Bővített séma a dokumentáció alapján

-- ============================================
-- TÖRZSADATOK
-- ============================================

-- Országok
CREATE TABLE IF NOT EXISTS countries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(3) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    name_en VARCHAR(100),
    is_eu BOOLEAN DEFAULT FALSE,
    is_eea BOOLEAN DEFAULT FALSE,
    is_high_risk BOOLEAN DEFAULT FALSE,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Megyék
CREATE TABLE IF NOT EXISTS counties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_id UUID REFERENCES countries(id),
    code VARCHAR(10) NOT NULL,
    name VARCHAR(100) NOT NULL,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Települések
CREATE TABLE IF NOT EXISTS cities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    county_id UUID REFERENCES counties(id),
    name VARCHAR(100) NOT NULL,
    post_code VARCHAR(10),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bankok
CREATE TABLE IF NOT EXISTS banks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(10) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    swift_code VARCHAR(11),
    country_id UUID REFERENCES countries(id),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dokumentum típusok
CREATE TABLE IF NOT EXISTS document_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_photo_id BOOLEAN DEFAULT FALSE,
    is_address_proof BOOLEAN DEFAULT FALSE,
    valid_for_identification BOOLEAN DEFAULT TRUE,
    sort_order INT DEFAULT 0,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Saját cégek (multi-tenant)
CREATE TABLE IF NOT EXISTS own_companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    tax_number VARCHAR(20),
    registration_number VARCHAR(30),
    address TEXT,
    phone VARCHAR(50),
    email VARCHAR(100),
    mnb_license_number VARCHAR(50),
    license_valid_from DATE,
    license_valid_to DATE,
    logo_url TEXT,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Munkaállomások
CREATE TABLE IF NOT EXISTS workstations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID REFERENCES branch(id) NOT NULL,
    code VARCHAR(20) NOT NULL,
    name VARCHAR(100),
    mac_address VARCHAR(50),
    ip_address VARCHAR(50),
    printer_name VARCHAR(100),
    receipt_printer_name VARCHAR(100),
    display_port VARCHAR(20),
    is_main_terminal BOOLEAN DEFAULT FALSE,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(branch_id, code)
);

-- ============================================
-- ÁRFOLYAM KEZELÉS
-- ============================================

-- Címletek
CREATE TABLE IF NOT EXISTS denominations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    currency_id UUID REFERENCES currency(id) NOT NULL,
    value DECIMAL(18,2) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('BANKNOTE', 'COIN')),
    image_url TEXT,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(currency_id, value, type)
);

-- Deviza csoportok (54 csoport)
CREATE TABLE IF NOT EXISTS currency_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    sort_order INT DEFAULT 0,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Fiók-csoport kapcsolat
CREATE TABLE IF NOT EXISTS branch_currency_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID REFERENCES branch(id) NOT NULL,
    currency_group_id UUID REFERENCES currency_groups(id) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(branch_id, currency_group_id)
);

-- Banki árfolyamok
CREATE TABLE IF NOT EXISTS bank_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bank_id UUID REFERENCES banks(id) NOT NULL,
    currency_id UUID REFERENCES currency(id) NOT NULL,
    buy_rate DECIMAL(18,6) NOT NULL,
    sell_rate DECIMAL(18,6) NOT NULL,
    mid_rate DECIMAL(18,6),
    rate_date DATE NOT NULL,
    valid_from TIMESTAMP,
    valid_to TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES workers(id)
);

-- Csoport árfolyamok
CREATE TABLE IF NOT EXISTS group_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    currency_group_id UUID REFERENCES currency_groups(id) NOT NULL,
    currency_id UUID REFERENCES currency(id) NOT NULL,
    buy_rate DECIMAL(18,6) NOT NULL,
    sell_rate DECIMAL(18,6) NOT NULL,
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES workers(id)
);

-- Saját árfolyamok (fiók felülbíráló)
CREATE TABLE IF NOT EXISTS own_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID REFERENCES branch(id) NOT NULL,
    currency_id UUID REFERENCES currency(id) NOT NULL,
    buy_rate DECIMAL(18,6),
    sell_rate DECIMAL(18,6),
    reason TEXT,
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP,
    approved_by UUID REFERENCES workers(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES workers(id)
);

-- Kedvezményes árfolyamok
CREATE TABLE IF NOT EXISTS discount_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID REFERENCES branch(id) NOT NULL,
    currency_id UUID REFERENCES currency(id) NOT NULL,
    tier VARCHAR(30) NOT NULL CHECK (tier IN ('TIER_0_50K', 'TIER_50K_300K', 'TIER_300K_1M', 'TIER_1M_PLUS')),
    type VARCHAR(20) NOT NULL CHECK (type IN ('PERCENTAGE', 'FIXED')),
    buy_discount_percent DECIMAL(10,4),
    sell_discount_percent DECIMAL(10,4),
    buy_discount_amount DECIMAL(18,6),
    sell_discount_amount DECIMAL(18,6),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Versenytársak
CREATE TABLE IF NOT EXISTS competitors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    phone VARCHAR(50),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Versenytárs árfolyamok
CREATE TABLE IF NOT EXISTS competitor_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    competitor_id UUID REFERENCES competitors(id) NOT NULL,
    currency_id UUID REFERENCES currency(id) NOT NULL,
    buy_rate DECIMAL(18,6),
    sell_rate DECIMAL(18,6),
    rate_date DATE NOT NULL,
    source VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES workers(id)
);

-- ============================================
-- DÍJ KEZELÉS
-- ============================================

-- Díjtípusok
CREATE TABLE IF NOT EXISTS fee_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    default_fee_percent DECIMAL(10,4),
    min_fee DECIMAL(18,2),
    max_fee DECIMAL(18,2),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Díj beállítások
CREATE TABLE IF NOT EXISTS fee_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID REFERENCES branch(id),
    currency_id UUID REFERENCES currency(id),
    fee_type_id UUID REFERENCES fee_types(id) NOT NULL,
    fee_percent DECIMAL(10,4),
    min_fee DECIMAL(18,2),
    max_fee DECIMAL(18,2),
    active BOOLEAN DEFAULT TRUE,
    valid_from TIMESTAMP,
    valid_to TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Díj sávok
CREATE TABLE IF NOT EXISTS fee_rate_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fee_rate_id UUID REFERENCES fee_rates(id) NOT NULL,
    from_amount DECIMAL(18,2) NOT NULL,
    to_amount DECIMAL(18,2),
    fee_percent DECIMAL(10,4),
    min_fee DECIMAL(18,2),
    max_fee DECIMAL(18,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- PÉNZTÁR KEZELÉS
-- ============================================

-- Pénztárak
CREATE TABLE IF NOT EXISTS cash_desks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID REFERENCES branch(id) NOT NULL,
    code VARCHAR(20) NOT NULL,
    name VARCHAR(100),
    type VARCHAR(30) NOT NULL CHECK (type IN ('MAIN', 'CASHIER', 'SAFE', 'ATM')),
    status VARCHAR(20) DEFAULT 'CLOSED' CHECK (status IN ('OPEN', 'CLOSED', 'SUSPENDED')),
    max_cash_limit DECIMAL(18,2),
    current_worker_id UUID REFERENCES workers(id),
    opened_at TIMESTAMP,
    last_activity_at TIMESTAMP,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(branch_id, code)
);

-- Pénztár egyenlegek devizánként
CREATE TABLE IF NOT EXISTS cash_balances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cash_desk_id UUID REFERENCES cash_desks(id) NOT NULL,
    currency_id UUID REFERENCES currency(id) NOT NULL,
    balance DECIMAL(18,2) NOT NULL DEFAULT 0,
    last_movement_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(cash_desk_id, currency_id)
);

-- Pénzmozgások
CREATE TABLE IF NOT EXISTS cash_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cash_desk_id UUID REFERENCES cash_desks(id) NOT NULL,
    currency_id UUID REFERENCES currency(id) NOT NULL,
    movement_type VARCHAR(30) NOT NULL CHECK (movement_type IN ('OPENING', 'CLOSING', 'TRANSFER_IN', 'TRANSFER_OUT', 'SALE', 'PURCHASE', 'ADJUSTMENT', 'EXCHANGE')),
    direction VARCHAR(10) NOT NULL CHECK (direction IN ('IN', 'OUT')),
    amount DECIMAL(18,2) NOT NULL,
    balance_before DECIMAL(18,2),
    balance_after DECIMAL(18,2),
    reference_type VARCHAR(50),
    reference_id UUID,
    notes TEXT,
    worker_id UUID REFERENCES workers(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Címlet egyenlegek
CREATE TABLE IF NOT EXISTS denomination_balances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cash_desk_id UUID REFERENCES cash_desks(id) NOT NULL,
    denomination_id UUID REFERENCES denominations(id) NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    last_count_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(cash_desk_id, denomination_id)
);

-- Munkamenet (shift)
CREATE TABLE IF NOT EXISTS workstation_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workstation_id UUID REFERENCES workstations(id),
    cash_desk_id UUID REFERENCES cash_desks(id) NOT NULL,
    worker_id UUID REFERENCES workers(id) NOT NULL,
    session_status VARCHAR(20) NOT NULL CHECK (session_status IN ('ACTIVE', 'BREAK', 'CLOSED', 'SUSPENDED')),
    opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP,
    opening_balance_huf DECIMAL(18,2),
    closing_balance_huf DECIMAL(18,2),
    transaction_count INT DEFAULT 0,
    notes TEXT,
    closed_by UUID REFERENCES workers(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Napi zárás
CREATE TABLE IF NOT EXISTS daily_closings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cash_desk_id UUID REFERENCES cash_desks(id) NOT NULL,
    closing_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('IN_PROGRESS', 'COMPLETED', 'DIFFERENCE', 'APPROVED')),
    closing_started_at TIMESTAMP,
    closing_completed_at TIMESTAMP,
    closing_worker_id UUID REFERENCES workers(id),
    supervisor_id UUID REFERENCES workers(id),
    opening_balance_huf DECIMAL(18,2),
    closing_balance_huf DECIMAL(18,2),
    difference_huf DECIMAL(18,2) DEFAULT 0,
    transaction_count INT DEFAULT 0,
    total_buy_huf DECIMAL(18,2) DEFAULT 0,
    total_sell_huf DECIMAL(18,2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(cash_desk_id, closing_date)
);

-- ============================================
-- ÜGYFÉL KEZELÉS
-- ============================================

-- Magánszemély ügyfelek
CREATE TABLE IF NOT EXISTS person_customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customer(id),
    title VARCHAR(20),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    birth_name VARCHAR(200),
    mother_name VARCHAR(200),
    birth_date DATE,
    birth_place VARCHAR(100),
    nationality VARCHAR(3),
    gender VARCHAR(10),
    document_type_id UUID REFERENCES document_types(id),
    document_number VARCHAR(50),
    document_issued_at DATE,
    document_expires_at DATE,
    document_issuer VARCHAR(100),
    tax_id VARCHAR(20),
    address_country VARCHAR(3),
    address_postal_code VARCHAR(10),
    address_city VARCHAR(100),
    address_street VARCHAR(200),
    phone VARCHAR(50),
    email VARCHAR(100),
    is_pep BOOLEAN DEFAULT FALSE,
    pep_position VARCHAR(200),
    is_eu_resident BOOLEAN DEFAULT TRUE,
    annual_transaction_total DECIMAL(18,2) DEFAULT 0,
    identification_level VARCHAR(20) DEFAULT 'SIMPLE',
    last_identification_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Céges ügyfelek
CREATE TABLE IF NOT EXISTS company_customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customer(id),
    company_name VARCHAR(200) NOT NULL,
    short_name VARCHAR(100),
    tax_number VARCHAR(20),
    eu_tax_number VARCHAR(30),
    registration_number VARCHAR(30),
    teaor_code VARCHAR(10),
    address_country VARCHAR(3),
    address_postal_code VARCHAR(10),
    address_city VARCHAR(100),
    address_street VARCHAR(200),
    mailing_address TEXT,
    phone VARCHAR(50),
    email VARCHAR(100),
    website VARCHAR(200),
    contact_person_name VARCHAR(200),
    contact_person_phone VARCHAR(50),
    is_exchange_office BOOLEAN DEFAULT FALSE,
    weekly_transaction_total DECIMAL(18,2) DEFAULT 0,
    annual_transaction_total DECIMAL(18,2) DEFAULT 0,
    identification_level VARCHAR(20) DEFAULT 'FULL',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tiltott cégek
CREATE TABLE IF NOT EXISTS prohibited_companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name VARCHAR(200) NOT NULL,
    tax_number VARCHAR(20),
    registration_number VARCHAR(30),
    reason TEXT,
    source VARCHAR(100),
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    added_by UUID REFERENCES workers(id),
    active BOOLEAN DEFAULT TRUE
);

-- Meghatalmazások
CREATE TABLE IF NOT EXISTS authorizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL,
    authorized_person_id UUID REFERENCES person_customers(id),
    authorization_type VARCHAR(30) NOT NULL CHECK (authorization_type IN ('FULL', 'LIMITED', 'ONE_TIME')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('ACTIVE', 'EXPIRED', 'REVOKED')),
    valid_from TIMESTAMP,
    valid_to TIMESTAMP,
    max_amount DECIMAL(18,2),
    allowed_currencies TEXT,
    document_path TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES workers(id)
);

-- ============================================
-- TRANZAKCIÓ BŐVÍTÉS
-- ============================================

-- Tranzakció tételek (több tétel egy tranzakcióban)
CREATE TABLE IF NOT EXISTS transaction_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID REFERENCES transaction(id) NOT NULL,
    currency_id UUID REFERENCES currency(id) NOT NULL,
    direction VARCHAR(10) NOT NULL CHECK (direction IN ('BUY', 'SELL')),
    foreign_amount DECIMAL(18,2) NOT NULL,
    rate DECIMAL(18,6) NOT NULL,
    huf_amount DECIMAL(18,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tranzakció díjak
CREATE TABLE IF NOT EXISTS transaction_fees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID REFERENCES transaction(id) NOT NULL,
    fee_type_id UUID REFERENCES fee_types(id) NOT NULL,
    fee_amount DECIMAL(18,2) NOT NULL,
    fee_currency_id UUID REFERENCES currency(id),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Foglalók
CREATE TABLE IF NOT EXISTS deposits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID REFERENCES branch(id) NOT NULL,
    customer_id UUID REFERENCES customer(id),
    currency_id UUID REFERENCES currency(id) NOT NULL,
    amount DECIMAL(18,2) NOT NULL,
    deposit_amount DECIMAL(18,2) NOT NULL,
    deposit_type VARCHAR(30) NOT NULL CHECK (deposit_type IN ('RESERVATION', 'PREPAYMENT', 'GUARANTEE')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('ACTIVE', 'USED', 'CANCELLED', 'EXPIRED')),
    reserved_rate DECIMAL(18,6),
    valid_until TIMESTAMP,
    transaction_id UUID REFERENCES transaction(id),
    notes TEXT,
    cancelled_reason TEXT,
    worker_id UUID REFERENCES workers(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TRANSZFER KEZELÉS
-- ============================================

-- Pénztárak közti transzferek
CREATE TABLE IF NOT EXISTS transfers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transfer_number VARCHAR(30) NOT NULL UNIQUE,
    source_cash_desk_id UUID REFERENCES cash_desks(id) NOT NULL,
    target_cash_desk_id UUID REFERENCES cash_desks(id) NOT NULL,
    status VARCHAR(30) NOT NULL CHECK (status IN ('PENDING', 'CONFIRMED', 'IN_TRANSIT', 'RECEIVED', 'DIFFERENCE', 'CANCELLED')),
    initiated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confirmed_at TIMESTAMP,
    received_at TIMESTAMP,
    initiated_by UUID REFERENCES workers(id),
    confirmed_by UUID REFERENCES workers(id),
    received_by UUID REFERENCES workers(id),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transzfer tételek
CREATE TABLE IF NOT EXISTS transfer_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transfer_id UUID REFERENCES transfers(id) NOT NULL,
    currency_id UUID REFERENCES currency(id) NOT NULL,
    sent_amount DECIMAL(18,2) NOT NULL,
    received_amount DECIMAL(18,2),
    difference DECIMAL(18,2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- JOGOSULTSÁG KEZELÉS
-- ============================================

-- Szerepkörök
CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Jogosultságok
CREATE TABLE IF NOT EXISTS permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Szerepkör-jogosultság kapcsolat
CREATE TABLE IF NOT EXISTS role_permissions (
    role_id UUID REFERENCES roles(id) NOT NULL,
    permission_id UUID REFERENCES permissions(id) NOT NULL,
    PRIMARY KEY (role_id, permission_id)
);

-- Felhasználók (a workers táblához kapcsolódik)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    full_name VARCHAR(200),
    role_id UUID REFERENCES roles(id),
    branch_id UUID REFERENCES branch(id),
    worker_id UUID REFERENCES workers(id),
    active BOOLEAN DEFAULT TRUE,
    must_change_password BOOLEAN DEFAULT FALSE,
    last_login_at TIMESTAMP,
    failed_login_count INT DEFAULT 0,
    locked_until TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- EGYÉB
-- ============================================

-- Körlevelek
CREATE TABLE IF NOT EXISTS newsletters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    priority VARCHAR(20) DEFAULT 'NORMAL' CHECK (priority IN ('LOW', 'NORMAL', 'HIGH', 'URGENT')),
    is_mandatory BOOLEAN DEFAULT FALSE,
    target_branch_id UUID REFERENCES branch(id),
    target_role_id UUID REFERENCES roles(id),
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP,
    created_by UUID REFERENCES workers(id),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Körlevél olvasás
CREATE TABLE IF NOT EXISTS newsletter_reads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    newsletter_id UUID REFERENCES newsletters(id) NOT NULL,
    user_id UUID REFERENCES users(id) NOT NULL,
    read_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confirmed_at TIMESTAMP,
    UNIQUE(newsletter_id, user_id)
);

-- POS terminálok
CREATE TABLE IF NOT EXISTS pos_terminals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID REFERENCES branch(id) NOT NULL,
    terminal_id VARCHAR(50) NOT NULL,
    name VARCHAR(100),
    provider VARCHAR(100),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(branch_id, terminal_id)
);

-- POS tranzakciók
CREATE TABLE IF NOT EXISTS pos_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pos_terminal_id UUID REFERENCES pos_terminals(id) NOT NULL,
    transaction_id UUID REFERENCES transaction(id),
    authorization_code VARCHAR(50),
    card_type VARCHAR(30),
    card_last_four VARCHAR(4),
    amount DECIMAL(18,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'HUF',
    status VARCHAR(20) NOT NULL CHECK (status IN ('PENDING', 'APPROVED', 'DECLINED', 'CANCELLED', 'REFUNDED')),
    processed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Készpénz szállítás
CREATE TABLE IF NOT EXISTS cash_transport_packages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    package_number VARCHAR(50) NOT NULL UNIQUE,
    source_type VARCHAR(30) NOT NULL CHECK (source_type IN ('BANK', 'BRANCH', 'HEADQUARTERS')),
    source_id UUID,
    target_type VARCHAR(30) NOT NULL CHECK (target_type IN ('BANK', 'BRANCH', 'HEADQUARTERS')),
    target_id UUID,
    status VARCHAR(30) NOT NULL CHECK (status IN ('PREPARING', 'READY', 'IN_TRANSIT', 'DELIVERED', 'CANCELLED')),
    scheduled_date DATE,
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP,
    total_huf DECIMAL(18,2),
    sealed_by UUID REFERENCES workers(id),
    received_by UUID REFERENCES workers(id),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit napló
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    user_id UUID REFERENCES users(id),
    worker_id UUID REFERENCES workers(id),
    branch_id UUID REFERENCES branch(id),
    ip_address VARCHAR(50),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- INDEXEK
-- ============================================

-- Árfolyam indexek
CREATE INDEX IF NOT EXISTS idx_bank_rates_date ON bank_rates(rate_date);
CREATE INDEX IF NOT EXISTS idx_group_rates_valid ON group_rates(valid_from, valid_to);
CREATE INDEX IF NOT EXISTS idx_own_rates_branch ON own_rates(branch_id, currency_id);

-- Pénztár indexek
CREATE INDEX IF NOT EXISTS idx_cash_movements_desk ON cash_movements(cash_desk_id, created_at);
CREATE INDEX IF NOT EXISTS idx_cash_balances_desk ON cash_balances(cash_desk_id);
CREATE INDEX IF NOT EXISTS idx_daily_closings_date ON daily_closings(closing_date);

-- Ügyfél indexek
CREATE INDEX IF NOT EXISTS idx_person_customers_doc ON person_customers(document_number);
CREATE INDEX IF NOT EXISTS idx_company_customers_tax ON company_customers(tax_number);
CREATE INDEX IF NOT EXISTS idx_authorizations_customer ON authorizations(customer_id, status);

-- Transzfer indexek
CREATE INDEX IF NOT EXISTS idx_transfers_status ON transfers(status);
CREATE INDEX IF NOT EXISTS idx_transfers_source ON transfers(source_cash_desk_id);
CREATE INDEX IF NOT EXISTS idx_transfers_target ON transfers(target_cash_desk_id);

-- Foglaló indexek
CREATE INDEX IF NOT EXISTS idx_deposits_status ON deposits(status, valid_until);
CREATE INDEX IF NOT EXISTS idx_deposits_branch ON deposits(branch_id);

-- Audit indexek
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action, created_at);

-- ============================================
-- KEZDŐ ADATOK
-- ============================================

-- Alap szerepkörök

-- Alap jogosultságok

-- Alap dokumentum típusok

-- Alap díjtípusok

-- ============================================
-- HR MODUL - JUTALÉKOK
-- ============================================

-- Dolgozó jutalékok
CREATE TABLE IF NOT EXISTS worker_commissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_id UUID REFERENCES workers(id) NOT NULL,
    branch_id UUID REFERENCES branch(id),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    transaction_count INT DEFAULT 0,
    total_transaction_amount DECIMAL(18,2) DEFAULT 0,
    commission_rate DECIMAL(10,4),
    commission_amount DECIMAL(18,2) DEFAULT 0,
    currency_id UUID REFERENCES currency(id),
    status_did UUID REFERENCES dictionary(id),
    calculation_date TIMESTAMP,
    calculated_by UUID REFERENCES workers(id),
    approval_date TIMESTAMP,
    approved_by UUID REFERENCES workers(id),
    payment_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_worker_commissions_worker ON worker_commissions(worker_id);
CREATE INDEX IF NOT EXISTS idx_worker_commissions_period ON worker_commissions(period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_worker_commissions_status ON worker_commissions(status_did);

-- ============================================
-- RENDSZERPARAMÉTEREK
-- ============================================

-- Rendszerparaméterek tábla
CREATE TABLE IF NOT EXISTS system_parameters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parameter_key VARCHAR(100) NOT NULL UNIQUE,
    parameter_value TEXT,
    parameter_type VARCHAR(50) NOT NULL,
    category VARCHAR(50),
    description TEXT,
    is_encrypted BOOLEAN DEFAULT FALSE,
    is_system BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    validation_rule TEXT,
    default_value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    created_by UUID REFERENCES workers(id),
    updated_by UUID REFERENCES workers(id)
);

CREATE INDEX IF NOT EXISTS idx_system_parameters_key ON system_parameters(parameter_key);
CREATE INDEX IF NOT EXISTS idx_system_parameters_category ON system_parameters(category);
CREATE INDEX IF NOT EXISTS idx_system_parameters_active ON system_parameters(is_active);

-- ============================================
-- SZERVEZETEK
-- ============================================

-- Szervezetek tábla
CREATE TABLE IF NOT EXISTS organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    short_name VARCHAR(100),
    tax_number VARCHAR(20),
    registration_number VARCHAR(30),
    parent_organization_id UUID REFERENCES organizations(id),
    country_id UUID REFERENCES countries(id),
    postal_code VARCHAR(10),
    city VARCHAR(100),
    address TEXT,
    phone VARCHAR(50),
    email VARCHAR(100),
    website VARCHAR(200),
    organization_type_did UUID REFERENCES dictionary(id),
    established_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    archived_at TIMESTAMP,
    archived_by UUID REFERENCES workers(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_organizations_code ON organizations(code);
CREATE INDEX IF NOT EXISTS idx_organizations_parent ON organizations(parent_organization_id);
CREATE INDEX IF NOT EXISTS idx_organizations_active ON organizations(is_active);

-- ============================================
-- SZERVEZETI RENDSZERPARAMÉTEREK
-- ============================================

-- Szervezeti rendszerparaméterek tábla
CREATE TABLE IF NOT EXISTS organizational_system_parameters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parameter_key VARCHAR(100) NOT NULL,
    parameter_value TEXT,
    parameter_type VARCHAR(50) NOT NULL,
    organization_id UUID REFERENCES organizations(id),
    currency_id UUID REFERENCES currency(id),
    valid_from DATE,
    valid_to DATE,
    category VARCHAR(50),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    archived_at TIMESTAMP,
    archived_by UUID REFERENCES workers(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    created_by UUID REFERENCES workers(id),
    updated_by UUID REFERENCES workers(id)
);

CREATE INDEX IF NOT EXISTS idx_org_system_params_key ON organizational_system_parameters(parameter_key);
CREATE INDEX IF NOT EXISTS idx_org_system_params_org ON organizational_system_parameters(organization_id);
CREATE INDEX IF NOT EXISTS idx_org_system_params_currency ON organizational_system_parameters(currency_id);
CREATE INDEX IF NOT EXISTS idx_org_system_params_active ON organizational_system_parameters(is_active);

-- ============================================
-- ANONIM BEJELENTÉSEK
-- ============================================

-- Anonim bejelentések tábla
CREATE TABLE IF NOT EXISTS anonymous_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_number VARCHAR(50) NOT NULL UNIQUE,
    report_type_did UUID REFERENCES dictionary(id) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    reported_person_name VARCHAR(255),
    reported_person_document_number VARCHAR(50),
    reported_company_name VARCHAR(255),
    reported_company_tax_number VARCHAR(20),
    incident_date DATE,
    incident_location VARCHAR(255),
    reporter_contact_info TEXT,
    status_did UUID REFERENCES dictionary(id) NOT NULL,
    priority_did UUID REFERENCES dictionary(id),
    assigned_to_worker_id UUID REFERENCES workers(id),
    review_notes TEXT,
    reviewed_by_worker_id UUID REFERENCES workers(id),
    reviewed_at TIMESTAMP,
    investigation_result TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_anonymous_reports_number ON anonymous_reports(report_number);
CREATE INDEX IF NOT EXISTS idx_anonymous_reports_status ON anonymous_reports(status_did);
CREATE INDEX IF NOT EXISTS idx_anonymous_reports_assigned ON anonymous_reports(assigned_to_worker_id);
CREATE INDEX IF NOT EXISTS idx_anonymous_reports_active ON anonymous_reports(is_active);

-- ============================================
-- JUTALÉK PARAMÉTEREZÉS
-- ============================================

-- Jutalék mértékek tábla
CREATE TABLE IF NOT EXISTS commission_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    branch_id UUID REFERENCES branch(id),
    currency_id UUID REFERENCES currency(id),
    transaction_type_did UUID REFERENCES dictionary(id),
    commission_type VARCHAR(20) NOT NULL,
    commission_rate DECIMAL(10,4) NOT NULL,
    min_amount DECIMAL(18,2),
    max_amount DECIMAL(18,2),
    min_commission DECIMAL(18,2),
    max_commission DECIMAL(18,2),
    valid_from DATE NOT NULL,
    valid_to DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    created_by UUID REFERENCES workers(id),
    updated_by UUID REFERENCES workers(id)
);

CREATE INDEX IF NOT EXISTS idx_commission_rates_code ON commission_rates(code);
CREATE INDEX IF NOT EXISTS idx_commission_rates_branch ON commission_rates(branch_id);
CREATE INDEX IF NOT EXISTS idx_commission_rates_currency ON commission_rates(currency_id);
CREATE INDEX IF NOT EXISTS idx_commission_rates_active ON commission_rates(is_active);
CREATE INDEX IF NOT EXISTS idx_commission_rates_valid ON commission_rates(valid_from, valid_to);

-- ============================================
-- ÁTADÓLAP
-- ============================================

-- Átadólap tábla
CREATE TABLE IF NOT EXISTS handover_sheets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sheet_number VARCHAR(50) NOT NULL UNIQUE,
    source_cash_desk_id UUID REFERENCES cash_desks(id) NOT NULL,
    target_cash_desk_id UUID REFERENCES cash_desks(id) NOT NULL,
    handover_date DATE NOT NULL,
    handed_over_by_worker_id UUID REFERENCES workers(id) NOT NULL,
    received_by_worker_id UUID REFERENCES workers(id),
    status_did UUID REFERENCES dictionary(id) NOT NULL,
    total_huf_amount DECIMAL(18,2),
    notes TEXT,
    discrepancy_notes TEXT,
    handed_over_at TIMESTAMP,
    received_at TIMESTAMP,
    verified_at TIMESTAMP,
    verified_by_worker_id UUID REFERENCES workers(id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

-- Átadólap tételek tábla
CREATE TABLE IF NOT EXISTS handover_sheet_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    handover_sheet_id UUID REFERENCES handover_sheets(id) NOT NULL,
    currency_id UUID REFERENCES currency(id) NOT NULL,
    amount DECIMAL(18,2) NOT NULL,
    denomination_details TEXT,
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_handover_sheets_number ON handover_sheets(sheet_number);
CREATE INDEX IF NOT EXISTS idx_handover_sheets_source ON handover_sheets(source_cash_desk_id);
CREATE INDEX IF NOT EXISTS idx_handover_sheets_target ON handover_sheets(target_cash_desk_id);
CREATE INDEX IF NOT EXISTS idx_handover_sheets_date ON handover_sheets(handover_date);
CREATE INDEX IF NOT EXISTS idx_handover_sheet_items_sheet ON handover_sheet_items(handover_sheet_id);

-- ============================================
-- BIZONYLATKEZELÉS
-- ============================================

-- Bizonylatok tábla
CREATE TABLE IF NOT EXISTS receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    receipt_number VARCHAR(50) NOT NULL UNIQUE,
    transaction_id UUID REFERENCES transaction(id),
    branch_id UUID REFERENCES branch(id) NOT NULL,
    cash_desk_id UUID REFERENCES cash_desks(id),
    receipt_type_did UUID REFERENCES dictionary(id) NOT NULL,
    nav_receipt_number VARCHAR(50),
    qr_code TEXT,
    receipt_data TEXT,
    printed_at TIMESTAMP,
    printed_by_worker_id UUID REFERENCES workers(id),
    sent_to_nav_at TIMESTAMP,
    nav_response TEXT,
    status_did UUID REFERENCES dictionary(id) NOT NULL,
    error_message TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_receipts_number ON receipts(receipt_number);
CREATE INDEX IF NOT EXISTS idx_receipts_nav_number ON receipts(nav_receipt_number);
CREATE INDEX IF NOT EXISTS idx_receipts_transaction ON receipts(transaction_id);
CREATE INDEX IF NOT EXISTS idx_receipts_branch ON receipts(branch_id);
CREATE INDEX IF NOT EXISTS idx_receipts_status ON receipts(status_did);

-- ============================================
-- CÍMLETEZÉSI MODUL
-- ============================================

-- Megjegyzés: A denomination_optimization és denomination_rule táblák már léteznek az adatbázisban
-- (002_valuta_fixed.sql), de itt ellenőrizzük, hogy minden szükséges mező megvan-e

-- Címletezési tranzakció napló tábla
CREATE TABLE IF NOT EXISTS denomination_transaction_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID REFERENCES transaction(id),
    denomination_rule_id UUID REFERENCES denomination_rule(id),
    denomination_optimization_id UUID REFERENCES denomination_optimization(id),
    currency_id UUID REFERENCES currency(id) NOT NULL,
    requested_amount DECIMAL(18,2) NOT NULL,
    actual_amount DECIMAL(18,2) NOT NULL,
    requested_denominations TEXT,
    actual_denominations TEXT,
    manual_override BOOLEAN DEFAULT FALSE,
    override_reason TEXT,
    performed_by UUID REFERENCES workers(id),
    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_denomination_log_transaction ON denomination_transaction_log(transaction_id);
CREATE INDEX IF NOT EXISTS idx_denomination_log_rule ON denomination_transaction_log(denomination_rule_id);
CREATE INDEX IF NOT EXISTS idx_denomination_log_currency ON denomination_transaction_log(currency_id);
CREATE INDEX IF NOT EXISTS idx_denomination_log_date ON denomination_transaction_log(log_date);
CREATE INDEX IF NOT EXISTS idx_denomination_log_override ON denomination_transaction_log(manual_override);

-- ============================================
-- JÁRULÉK KEZELÉS
-- ============================================

-- Járulékok (dolgozók járulékainak/jutalékainak időszakos kezelése)
CREATE TABLE IF NOT EXISTS contributions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_id UUID NOT NULL REFERENCES workers(id),
    branch_id UUID REFERENCES branch(id),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    contribution_type_did UUID NOT NULL REFERENCES dictionary(id),
    base_amount DECIMAL(18,2) NOT NULL,
    rate DECIMAL(10,4),
    calculated_amount DECIMAL(18,2) NOT NULL,
    transaction_count INTEGER,
    total_volume DECIMAL(18,2),
    currency_id UUID REFERENCES currency(id),
    status_did UUID NOT NULL REFERENCES dictionary(id),
    calculation_date TIMESTAMP,
    calculated_by UUID REFERENCES workers(id),
    approval_date TIMESTAMP,
    approved_by UUID REFERENCES workers(id),
    payment_date DATE,
    notes TEXT,
    calculation_details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_contributions_worker ON contributions(worker_id);
CREATE INDEX IF NOT EXISTS idx_contributions_branch ON contributions(branch_id);
CREATE INDEX IF NOT EXISTS idx_contributions_period ON contributions(period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_contributions_status ON contributions(status_did);

-- ============================================
-- TECHNIKAI FUNKCIÓK
-- ============================================

-- Pénztárszünetek
CREATE TABLE IF NOT EXISTS cash_desk_breaks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cash_desk_id UUID NOT NULL REFERENCES cash_desks(id),
    worker_id UUID NOT NULL REFERENCES workers(id),
    break_type_did UUID NOT NULL REFERENCES dictionary(id),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    planned_duration_minutes INTEGER,
    actual_duration_minutes INTEGER,
    status_did UUID NOT NULL REFERENCES dictionary(id),
    reason TEXT,
    notes TEXT,
    approved_by UUID REFERENCES workers(id),
    approval_time TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_cash_desk_breaks_cash_desk ON cash_desk_breaks(cash_desk_id);
CREATE INDEX IF NOT EXISTS idx_cash_desk_breaks_worker ON cash_desk_breaks(worker_id);
CREATE INDEX IF NOT EXISTS idx_cash_desk_breaks_status ON cash_desk_breaks(status_did);
CREATE INDEX IF NOT EXISTS idx_cash_desk_breaks_start_time ON cash_desk_breaks(start_time);