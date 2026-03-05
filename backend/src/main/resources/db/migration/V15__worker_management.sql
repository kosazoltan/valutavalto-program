-- V15: Pénztáros kezelés — jelenlét és szünet tracking
-- Worker attendance (bejelentkezés/kijelentkezés napló)
CREATE TABLE IF NOT EXISTS worker_attendance (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_id       BIGINT NOT NULL REFERENCES worker(id),
    branch_id       UUID NOT NULL,
    login_at        TIMESTAMP NOT NULL DEFAULT NOW(),
    logout_at       TIMESTAMP,
    ip_address      VARCHAR(50),
    user_agent      VARCHAR(500),
    session_token   VARCHAR(100),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_worker_attendance_worker ON worker_attendance(worker_id);
CREATE INDEX idx_worker_attendance_login ON worker_attendance(login_at);

-- Worker breaks (szünet kezelés)
CREATE TABLE IF NOT EXISTS worker_break (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_id       BIGINT NOT NULL REFERENCES worker(id),
    branch_id       UUID NOT NULL,
    break_start     TIMESTAMP NOT NULL DEFAULT NOW(),
    break_end       TIMESTAMP,
    reason          VARCHAR(200),
    approved_by     VARCHAR(100),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_worker_break_worker ON worker_break(worker_id);
CREATE INDEX idx_worker_break_start ON worker_break(break_start);
