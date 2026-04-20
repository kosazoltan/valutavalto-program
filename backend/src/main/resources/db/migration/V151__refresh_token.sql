-- V151: Refresh token entitas a HttpOnly cookie-s auth flow-hoz
-- Vezerlokonyv par.12.3: access token 15 perc (JWT), refresh token 7 nap (UUID, DB-ben)
-- A refresh token:
--   - UUID v4 formaban generalva
--   - BCrypt-tel hashelve, hogy DB szivargas eseten ne legyen azonnal hasznalhato
--   - HttpOnly + Secure + SameSite=Strict cookie-ban
--   - Path=/api/v1/auth/refresh - csak ez az endpoint kapja meg
--   - Token rotation: refresh-kor a regi torlodik, uj jon helyette

CREATE TABLE refresh_token (
    id              BIGSERIAL PRIMARY KEY,
    token_hash      VARCHAR(255) NOT NULL UNIQUE,
    worker_id       BIGINT NOT NULL REFERENCES worker(id) ON DELETE CASCADE,
    company_id      UUID NOT NULL,
    issued_at       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at      TIMESTAMP WITH TIME ZONE NOT NULL,
    revoked_at      TIMESTAMP WITH TIME ZONE,
    replaced_by     VARCHAR(255),  -- a kovetkezo token hash-e (token rotation auditloghoz)
    user_agent      VARCHAR(512),
    ip_address      VARCHAR(45),   -- IPv4 vagy IPv6
    CONSTRAINT refresh_token_worker_active_lookup UNIQUE (worker_id, token_hash)
);

CREATE INDEX idx_refresh_token_worker ON refresh_token(worker_id) WHERE revoked_at IS NULL;
CREATE INDEX idx_refresh_token_expires ON refresh_token(expires_at) WHERE revoked_at IS NULL;
CREATE INDEX idx_refresh_token_company ON refresh_token(company_id);

COMMENT ON TABLE refresh_token IS 'JWT refresh tokenek - HttpOnly cookie auth flow (vezerlokonyv par.12.3)';
COMMENT ON COLUMN refresh_token.token_hash IS 'BCrypt hash az eredeti UUID-rol (hogy DB szivargas eseten ne legyen hasznalhato)';
COMMENT ON COLUMN refresh_token.replaced_by IS 'Token rotation: ha refresh megtortent, ez a kovetkezo token hash-e';
