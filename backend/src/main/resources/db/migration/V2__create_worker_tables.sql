-- ============================================
-- Phase 2: Worker Management + JWT Auth
-- Multi-tenant support: company_id in ALL tables!
-- ============================================

-- Worker table
CREATE TABLE worker (
    id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    code VARCHAR(10) NOT NULL,
    name VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')),
    branch_id UUID NOT NULL REFERENCES branch(id) ON DELETE RESTRICT,
    active BOOLEAN NOT NULL DEFAULT true,
    phone VARCHAR(20),
    email VARCHAR(100),
    otp_user_id VARCHAR(50),
    otp_enabled BOOLEAN DEFAULT false,
    last_login_at TIMESTAMP,
    password_changed_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    
    -- Unique constraint: code unique within company
    CONSTRAINT uk_worker_company_code UNIQUE (company_id, code)
);

-- Index for fast lookups
CREATE INDEX idx_worker_company ON worker(company_id);
CREATE INDEX idx_worker_branch ON worker(branch_id);
CREATE INDEX idx_worker_active ON worker(active);
CREATE INDEX idx_worker_code ON worker(code);

-- Worker session table (login/logout tracking)
CREATE TABLE worker_session (
    id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    worker_id BIGINT NOT NULL REFERENCES worker(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branch(id) ON DELETE RESTRICT,
    login_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    logout_at TIMESTAMP,
    ip_address VARCHAR(45), -- IPv6 support
    user_agent TEXT,
    token_id VARCHAR(100)
);

-- Index for session queries
CREATE INDEX idx_session_worker ON worker_session(worker_id);
CREATE INDEX idx_session_company ON worker_session(company_id);
CREATE INDEX idx_session_login_at ON worker_session(login_at DESC);
CREATE INDEX idx_session_token_id ON worker_session(token_id);

-- Comments
COMMENT ON TABLE worker IS 'Munkavállalók (pénztárosok) - multi-tenant';
COMMENT ON COLUMN worker.company_id IS 'Cég (multi-tenant!)';
COMMENT ON COLUMN worker.code IS 'Pénztáros ID (pl. P001) - company-n belül egyedi';
COMMENT ON COLUMN worker.role IS 'CASHIER|SUPERVISOR|MANAGER|ADMIN';
COMMENT ON COLUMN worker.otp_user_id IS 'OTP terminal user ID (Phase 9)';

COMMENT ON TABLE worker_session IS 'Belépési történet tracking';
COMMENT ON COLUMN worker_session.token_id IS 'JWT token ID (session invalidation)';
