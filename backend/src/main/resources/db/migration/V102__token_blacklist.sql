-- V102: Token blacklist tábla — kijelentkezéskor a JWT tokenId-t ide mentjük,
-- így a filter elutasítja a már kijelentkezett tokeneket a lejáratukig.

CREATE TABLE token_blacklist (
    id              BIGSERIAL PRIMARY KEY,
    token_id        VARCHAR(64)  NOT NULL UNIQUE,
    worker_id       BIGINT       NOT NULL,
    blacklisted_at  TIMESTAMP    NOT NULL DEFAULT NOW(),
    reason          VARCHAR(50)  NOT NULL DEFAULT 'LOGOUT',
    expires_at      TIMESTAMP    NOT NULL
);

CREATE INDEX idx_token_blacklist_token_id ON token_blacklist (token_id);
CREATE INDEX idx_token_blacklist_expires_at ON token_blacklist (expires_at);

COMMENT ON TABLE token_blacklist IS 'Visszavont JWT tokenek nyilvántartása — kijelentkezés vagy kényszerített érvénytelenítés';
