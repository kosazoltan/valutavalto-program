CREATE TABLE IF NOT EXISTS bank_api_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_name VARCHAR(40) NOT NULL UNIQUE,
    mode VARCHAR(40) NOT NULL DEFAULT 'HTML_SCRAPING_FALLBACK',
    endpoint_url TEXT,
    auth_type VARCHAR(40) NOT NULL DEFAULT 'NONE',
    client_id VARCHAR(255),
    client_secret_encrypted TEXT,
    mtls_certificate_alias VARCHAR(255),
    update_frequency VARCHAR(120) NOT NULL DEFAULT '0 0 8 * * MON-FRI',
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    last_run_timestamp TIMESTAMP,
    last_run_status VARCHAR(30) NOT NULL DEFAULT 'NEVER_RUN',
    last_run_message TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_bank_api_config_enabled ON bank_api_config (enabled);

INSERT INTO bank_api_config (
    provider_name,
    mode,
    endpoint_url,
    auth_type,
    update_frequency,
    enabled,
    last_run_status
) VALUES (
    'RAIFFEISEN',
    'HTML_SCRAPING_FALLBACK',
    'https://www.raiffeisen.hu/hasznos/arfolyamok/lakossagi/deviza%C3%A1rfolyamok-bej%C3%B6v%C5%91-%C3%A9s-bankon-bel%C3%BCli-%C3%A1tutal%C3%A1si-tranzakci%C3%B3k-elsz%C3%A1mol%C3%A1s%C3%A1hoz',
    'NONE',
    '0 0 8 * * MON-FRI',
    TRUE,
    'NEVER_RUN'
) ON CONFLICT (provider_name) DO NOTHING;

INSERT INTO bank_api_config (
    provider_name,
    mode,
    auth_type,
    update_frequency,
    enabled,
    last_run_status
) VALUES (
    'MNB',
    'HTML_SCRAPING_FALLBACK',
    'NONE',
    'ON_DEMAND',
    TRUE,
    'NEVER_RUN'
) ON CONFLICT (provider_name) DO NOTHING;
