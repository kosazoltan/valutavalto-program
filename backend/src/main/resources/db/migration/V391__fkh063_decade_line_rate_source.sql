-- V391: FKH-063 — rate provenance on the decade report lines.
--
-- Background: DecadeReportService values decade stock from the MNB cache only
-- (mnb_exchange_rate_cache, source='MNB'). MNB does not quote BAM/BRL/EUA/ILS/MXN/NZD/RSD/THB and
-- neither does Raiffeisen, so the main vault records those rates by hand through the FK-028
-- screen (mnb_settlement_rate / mnb_settlement_rate_history). Once the decade report may use that
-- manual rate, the report line MUST record WHICH source produced the value: presenting a
-- hand-entered rate as an official MNB rate would be a false statutory claim (invariant #5).
--
-- Scope: additive columns only. No backfill — existing rows keep NULL, which is the honest value
-- ("provenance unknown"); retroactively stamping 'MNB' on historical rows would fabricate an
-- audit claim. NULL is also the correct value for a zero-stock line, where no rate is resolved
-- at all (FKH-061).
--
-- Money impact: none by itself. This migration only adds the provenance columns; the resolution
-- logic lands in the same PR's service change.

ALTER TABLE decade_report_line
    ADD COLUMN IF NOT EXISTS opening_rate_source VARCHAR(24);

ALTER TABLE decade_report_line
    ADD COLUMN IF NOT EXISTS closing_rate_source VARCHAR(24);

-- PostgreSQL has no "ALTER TABLE ... ADD CONSTRAINT IF NOT EXISTS", so the guard is explicit
-- (pattern: V234__audit_log_immutable_hash_chain.sql). Repeating the migration must be a no-op.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ck_decade_report_line_opening_rate_source'
      AND conrelid = 'decade_report_line'::regclass
  ) THEN
    ALTER TABLE decade_report_line
      ADD CONSTRAINT ck_decade_report_line_opening_rate_source
      CHECK (opening_rate_source IS NULL
             OR opening_rate_source IN ('MNB', 'MANUAL_SETTLEMENT'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ck_decade_report_line_closing_rate_source'
      AND conrelid = 'decade_report_line'::regclass
  ) THEN
    ALTER TABLE decade_report_line
      ADD CONSTRAINT ck_decade_report_line_closing_rate_source
      CHECK (closing_rate_source IS NULL
             OR closing_rate_source IN ('MNB', 'MANUAL_SETTLEMENT'));
  END IF;
END $$;

COMMENT ON COLUMN decade_report_line.opening_rate_source IS
  'FKH-063: provenance of opening_mnb_rate — MNB (official cache) or MANUAL_SETTLEMENT (FK-028 hand-entered); NULL = no rate resolved (zero stock) or legacy row';
COMMENT ON COLUMN decade_report_line.closing_rate_source IS
  'FKH-063: provenance of closing_mnb_rate — MNB (official cache) or MANUAL_SETTLEMENT (FK-028 hand-entered); NULL = no rate resolved (zero stock) or legacy row';
