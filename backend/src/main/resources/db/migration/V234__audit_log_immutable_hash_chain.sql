-- ===========================================================================
-- V234 — Audit log tabla immutable + uj mezok az AI-olvashato log+audit
--        modulhoz (event_id, trace_id, before_state, after_state, etc)
-- ===========================================================================
--
-- Forras: vault/feedback/valutavalto-belso-log-audit-modul-tervezet-2026-05-18.md (4.1)
-- Cel: Pmt/NAV/AML compliance + Hangseged session-start hibafigyel.
--
-- A meglevo `audit_log` tablat (V25 hozta letre) NEM toroljuk, csak BOVITJUK:
--   - event_id UUID UNIQUE (idempotency-tamogatas, kliens-szukseg)
--   - ts TIMESTAMPTZ (uj, idozona-tudatos; a regi `created_at` LocalDateTime marad)
--   - before_state / after_state JSONB (parsolhato, sokkal jobb mint a regi changes TEXT)
--   - amount + currency + receipt_number (penzugyi-szintu szuringes)
--   - trace_id (32-hex, W3C TraceContext)
--   - client_context (CASHIER | TREASURY_HQ | RFM | ADMIN)
--   - signed_by (manager-approval audit)
--   - worker_role + worker_id (UUID) - a regi user_id/user_name VARCHAR marad backward-compat
--   - event_type (uj, az AI-olvashato categorizalashoz)
--
-- Plus: immutable trigger (UPDATE + DELETE blokk).
-- A meglevo `entry_hash` / `previous_hash` mezok megmaradnak, ezek backward-compat
-- a meglevo AuditLogService.hashChain logikajaval.
-- ===========================================================================

-- 1. Uj mezok (idempotens IF NOT EXISTS-szel)
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS event_id UUID;
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS ts TIMESTAMPTZ;
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS event_type VARCHAR(80);
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS before_state JSONB;
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS after_state JSONB;
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS amount NUMERIC(18, 2);
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS currency VARCHAR(3);
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS receipt_number VARCHAR(20);
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS trace_id VARCHAR(32);
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS client_context VARCHAR(20);
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS signed_by VARCHAR(80);
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS worker_role VARCHAR(40);

-- 2. `event_id` UNIQUE constraint (idempotency)
-- Idempotens: csak akkor adunk hozza, ha meg nincs ilyen unique constraint
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'audit_log_event_id_unique'
  ) THEN
    -- Eloszor backfill NULL-okat unique UUID-vel a meglevo rekordoknak,
    -- hogy a UNIQUE constraint ne ervenytelenuljon
    UPDATE audit_log SET event_id = gen_random_uuid() WHERE event_id IS NULL;
    ALTER TABLE audit_log
      ADD CONSTRAINT audit_log_event_id_unique UNIQUE (event_id);
  END IF;
END $$;

-- 3. `ts` backfill a `created_at`-bol (UTC-be konvertalas)
UPDATE audit_log SET ts = created_at AT TIME ZONE 'UTC' WHERE ts IS NULL;

-- 4. Uj indexek a tipikus AI-keresesi minta szerint
CREATE INDEX IF NOT EXISTS idx_audit_log_trace_id
  ON audit_log (trace_id)
  WHERE trace_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_audit_log_event_type_ts
  ON audit_log (event_type, ts DESC)
  WHERE event_type IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_audit_log_entity_ts
  ON audit_log (entity_type, entity_id, ts DESC);

-- 5. KRITIKUS: immutable triggers (UPDATE + DELETE blokk)
-- Megj.: a meglevo AuditLogService CSAK save()-elt (INSERT), tehat ez NEM tor el
-- semmilyen meglevo flow-t. Ha a jovoben valaki UPDATE-elne, exception jon.

CREATE OR REPLACE FUNCTION audit_log_immutable() RETURNS TRIGGER AS $$
BEGIN
  -- Copilot PR #681 P2 fix: csak stabil oszlopokra hivatkozunk (action, id).
  -- Az event_type a V234-ben jott letre, igy ha valaki a triggert ujboltja
  -- egy regi snapshot-on, NEM doblunk "record old has no field event_type" hibat.
  RAISE EXCEPTION 'audit_log immutable: % operation not allowed (id=%, action=%)',
    TG_OP,
    COALESCE(OLD.id::TEXT, NEW.id::TEXT, 'unknown'),
    COALESCE(OLD.action, NEW.action, 'unknown');
  -- Defenziv: a RAISE EXCEPTION mar abortolja a function-t, de explicit
  -- RETURN NULL hozzaadva ha valaki a jovoben demote-olna warning-ra.
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS audit_log_no_update ON audit_log;
CREATE TRIGGER audit_log_no_update
  BEFORE UPDATE ON audit_log
  FOR EACH ROW
  EXECUTE FUNCTION audit_log_immutable();

DROP TRIGGER IF EXISTS audit_log_no_delete ON audit_log;
CREATE TRIGGER audit_log_no_delete
  BEFORE DELETE ON audit_log
  FOR EACH ROW
  EXECUTE FUNCTION audit_log_immutable();

-- 6. Smoke check: a tabla mezo-listaja teljes
DO $$
BEGIN
  ASSERT (SELECT COUNT(*) FROM information_schema.columns
          WHERE table_name = 'audit_log'
            AND column_name IN ('event_id','ts','before_state','after_state',
                                'amount','currency','receipt_number','trace_id',
                                'client_context','signed_by','worker_role','event_type'))
         = 12,
         'V234 smoke check failed: hianyzik valamelyik uj oszlop';
END $$;

COMMENT ON COLUMN audit_log.event_id IS 'Globalisan egyedi UUID (idempotency-tamogatas, V234)';
COMMENT ON COLUMN audit_log.ts IS 'TIMESTAMPTZ - idozona-tudatos timestamp (V234)';
COMMENT ON COLUMN audit_log.trace_id IS 'W3C TraceContext 32-hex - kliens-backend korrelacio (V234)';
COMMENT ON COLUMN audit_log.before_state IS 'JSONB - eloző allapot UPDATE-nel (V234)';
COMMENT ON COLUMN audit_log.after_state IS 'JSONB - uj allapot (V234)';
