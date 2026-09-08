-- FK-106: unused closing_control.alert_level (NONE/WARNING/CRITICAL) is not rendered.
-- CASCADE drops the inline CHECK from V11 and idx_closing_control_alert.
-- Never edit V11 (applied checksum). DROP is idempotent.

ALTER TABLE closing_control DROP COLUMN IF EXISTS alert_level CASCADE;
