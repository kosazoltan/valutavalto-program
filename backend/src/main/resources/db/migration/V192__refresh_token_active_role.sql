-- Preserve the selected operational role across HttpOnly refresh-cookie rotations.
-- Without this, multi-role workers could silently fall back to the first role
-- after a page reload or access-token expiry.

ALTER TABLE refresh_token
    ADD COLUMN IF NOT EXISTS active_role VARCHAR(64);

COMMENT ON COLUMN refresh_token.active_role IS
    'Selected operational role for silent refresh token regeneration (null for legacy/no-role sessions).';
