-- V392: FKH-067 (spec doc: FKH-063) — exchange-rate TTL made non-blocking after a configured cutoff
--
-- Context: cashier transactions recorded offline were blocked at sync time because the EUR rate had
-- not been refreshed for ~100 days (720h TTL exceeded). The cashier always trades at the rate that
-- was actually printed, so a stale rate must not block NEW transactions — but the items recorded
-- BEFORE the rollout must keep the old, blocking rule (no accidental automatic unblocking by the
-- background retry).
--
-- (a) transaction.client_created_at: the client-side, unchanged creation timestamp
--     (penztar-client pending_transactions.created_at). Optional, internal/audit use only.
-- (b) TTL_NONBLOCKING_CUTOFF system parameter with a SAFE DEFAULT: the seeded row carries an EMPTY
--     value, and SystemParameterService.findEffectiveValue filters blank values to Optional.empty(),
--     so ExchangeRateService keeps blocking EVERY transaction until an administrator consciously
--     sets an ISO-8601 instant. There is no accidental switch-on on a fresh install.
--
-- Idempotent: ADD COLUMN IF NOT EXISTS + insert-if-missing on the GLOBAL row (V364 pattern).

ALTER TABLE transaction
    ADD COLUMN IF NOT EXISTS client_created_at TIMESTAMP;

COMMENT ON COLUMN transaction.client_created_at IS
    'FKH-067: client-side unchanged creation timestamp from penztar-client (pending_transactions.created_at). Decides whether an expired exchange rate blocks the booking (see TTL_NONBLOCKING_CUTOFF). NULL for older client versions or non-client-originated transactions.';

INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
SELECT gen_random_uuid(), 'TTL_NONBLOCKING_CUTOFF', '', 'DATETIME', 'TRANSACTION',
       'FKH-067: az az idopont (ISO-8601, pl. 2026-09-12T06:00:00Z), amely UTAN a kliensen rogzitett '
       || 'tranzakciokra a lejart arfolyam mar nem blokkol, csak figyelmeztet + STALE_RATE_TRANSACTION_COMMITTED '
       || 'auditot ir. URES ertek = biztonsagos alapertelmezes, minden tranzakcio a regi, blokkolo szabaly ala esik.',
       true
WHERE NOT EXISTS (
    -- Only the GLOBAL row matters as the default (V348/V364 pattern): an existing company-scoped
    -- override must not suppress the global seed.
    SELECT 1 FROM system_parameter
     WHERE parameter_key = 'TTL_NONBLOCKING_CUTOFF' AND company_id IS NULL
);
