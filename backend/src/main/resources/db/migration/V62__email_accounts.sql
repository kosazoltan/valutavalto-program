-- V62__email_accounts.sql
-- Gmail integration: email_account and email_cache tables

-- Create email_account table
CREATE TABLE email_account (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID REFERENCES branch(id) ON DELETE SET NULL,
    vault_territory_id INTEGER REFERENCES vault_territory(id) ON DELETE SET NULL,
    own_company_id UUID REFERENCES own_company(id) ON DELETE SET NULL,
    worker_id BIGINT REFERENCES worker(id) ON DELETE SET NULL,
    gmail_address VARCHAR(200) NOT NULL,
    display_name VARCHAR(200),
    oauth_access_token TEXT,
    oauth_refresh_token TEXT,
    oauth_token_expiry TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT true,
    last_sync_at TIMESTAMP,
    sync_error TEXT,
    configured_by_worker_id BIGINT REFERENCES worker(id) ON DELETE RESTRICT,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    CONSTRAINT exactly_one_owner CHECK (
        (CASE WHEN branch_id IS NOT NULL THEN 1 ELSE 0 END +
         CASE WHEN vault_territory_id IS NOT NULL THEN 1 ELSE 0 END +
         CASE WHEN own_company_id IS NOT NULL THEN 1 ELSE 0 END +
         CASE WHEN worker_id IS NOT NULL THEN 1 ELSE 0 END) = 1
    )
);

-- Indexes on email_account
CREATE INDEX idx_email_account_branch_id ON email_account(branch_id);
CREATE INDEX idx_email_account_vault_territory_id ON email_account(vault_territory_id);
CREATE INDEX idx_email_account_worker_id ON email_account(worker_id);
CREATE INDEX idx_email_account_own_company_id ON email_account(own_company_id);
CREATE INDEX idx_email_account_is_active ON email_account(is_active);

-- Create email_cache table
CREATE TABLE email_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email_account_id UUID NOT NULL REFERENCES email_account(id) ON DELETE CASCADE,
    gmail_message_id VARCHAR(100) NOT NULL,
    thread_id VARCHAR(100),
    subject VARCHAR(500),
    sender_address VARCHAR(300),
    recipients TEXT,
    snippet VARCHAR(500),
    has_attachments BOOLEAN DEFAULT false,
    is_read BOOLEAN DEFAULT false,
    is_starred BOOLEAN DEFAULT false,
    label_ids TEXT,
    received_at TIMESTAMP NOT NULL,
    cached_at TIMESTAMP NOT NULL DEFAULT now(),
    UNIQUE(email_account_id, gmail_message_id)
);

-- Indexes on email_cache
CREATE INDEX idx_email_cache_account_received ON email_cache(email_account_id, received_at DESC);
CREATE INDEX idx_email_cache_gmail_message_id ON email_cache(gmail_message_id);
CREATE INDEX idx_email_cache_thread_id ON email_cache(thread_id);
