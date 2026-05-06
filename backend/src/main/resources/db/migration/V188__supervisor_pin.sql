-- P2-2 Supervisor PIN — gyors jóváhagyás 4-6 számjeggyel a jelszó helyett.
--
-- Üzleti motivácó: sztornó / supervisor-jóváhagyás műveletek 5-10 másodpercben
-- végrehajthatók (jelszó-bevitel + lookup helyett 4-6 számjegy auto-submit).
--
-- Biztonsági alapelvek:
-- - BCrypt hash (10 round, ugyanaz mint a password_hash)
-- - PIN nem helyettesíti a jelszót — opcionális gyors-engedély
-- - Rate limit: 3 hibás próbálkozás → 5 perc lockout (per workerCode)
-- - Audit log minden PIN-verify-re (success + fail)
-- - Minimum 4, maximum 6 számjegy (4-6 digit numeric)

ALTER TABLE worker
    ADD COLUMN IF NOT EXISTS supervisor_pin VARCHAR(60),  -- BCrypt hash (60 char)
    ADD COLUMN IF NOT EXISTS supervisor_pin_changed_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS supervisor_pin_last_used_at TIMESTAMP;

-- Lockout tábla a hibás próbálkozásokhoz (rate-limiting)
CREATE TABLE IF NOT EXISTS supervisor_pin_attempt (
    id BIGSERIAL PRIMARY KEY,
    worker_id BIGINT NOT NULL REFERENCES worker(id) ON DELETE CASCADE,
    attempt_at TIMESTAMP NOT NULL DEFAULT NOW(),
    success BOOLEAN NOT NULL,
    client_ip VARCHAR(45),
    user_agent VARCHAR(300)
);

CREATE INDEX IF NOT EXISTS idx_supervisor_pin_attempt_worker_time
    ON supervisor_pin_attempt(worker_id, attempt_at DESC);

COMMENT ON COLUMN worker.supervisor_pin IS
    'P2-2: 4-6 számjegyű supervisor PIN BCrypt-elt hash-e. NULL = nincs PIN beállítva. '
    'A jelszót NEM helyettesíti, csak gyors-engedélyhez használható (sztornó, '
    'supervisor-jóváhagyás).';

COMMENT ON TABLE supervisor_pin_attempt IS
    'P2-2 rate-limiting: 3 hibás próbálkozás 5 percen belül → lockout. '
    'A lockout-ot a SupervisorPinService nézi runtime-ban.';
