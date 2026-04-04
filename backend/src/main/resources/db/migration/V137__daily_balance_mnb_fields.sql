-- V100: MNB gyűjtő készlet/mozgás mezők bővítése (S1-01)
-- Legacy: Delphi MNB gyűjtő DLL mezők (BANKIATVETEL, BANKIATADAS, TOBBLET, HIANY, VISSZAPLUSZ, VISSZAMINUSZ, BANKKARTYA)

ALTER TABLE daily_balance ADD COLUMN IF NOT EXISTS bank_in NUMERIC(18,2) NOT NULL DEFAULT 0;
ALTER TABLE daily_balance ADD COLUMN IF NOT EXISTS bank_out NUMERIC(18,2) NOT NULL DEFAULT 0;
ALTER TABLE daily_balance ADD COLUMN IF NOT EXISTS surplus NUMERIC(18,2) NOT NULL DEFAULT 0;
ALTER TABLE daily_balance ADD COLUMN IF NOT EXISTS shortage NUMERIC(18,2) NOT NULL DEFAULT 0;
ALTER TABLE daily_balance ADD COLUMN IF NOT EXISTS returns_in NUMERIC(18,2) NOT NULL DEFAULT 0;
ALTER TABLE daily_balance ADD COLUMN IF NOT EXISTS returns_out NUMERIC(18,2) NOT NULL DEFAULT 0;
ALTER TABLE daily_balance ADD COLUMN IF NOT EXISTS card_payment NUMERIC(18,2) NOT NULL DEFAULT 0;
ALTER TABLE daily_balance ADD COLUMN IF NOT EXISTS calculated_closing NUMERIC(18,2);
ALTER TABLE daily_balance ADD COLUMN IF NOT EXISTS validation_status VARCHAR(5);

COMMENT ON COLUMN daily_balance.bank_in IS 'Banki átvétel — Delphi: BANKIATVETEL';
COMMENT ON COLUMN daily_balance.bank_out IS 'Banki átadás — Delphi: BANKIATADAS';
COMMENT ON COLUMN daily_balance.surplus IS 'Készlettöbblet — Delphi: TOBBLET';
COMMENT ON COLUMN daily_balance.shortage IS 'Készlethiány — Delphi: HIANY';
COMMENT ON COLUMN daily_balance.returns_in IS 'Visszavétel bejövő — Delphi: VISSZAPLUSZ';
COMMENT ON COLUMN daily_balance.returns_out IS 'Visszavétel kimenő — Delphi: VISSZAMINUSZ';
COMMENT ON COLUMN daily_balance.card_payment IS 'Bankkártyás forgalom HUF — Delphi: BANKKARTYA';
COMMENT ON COLUMN daily_balance.calculated_closing IS 'Számított záró (bevétel - kiadás)';
COMMENT ON COLUMN daily_balance.validation_status IS 'Validáció: OK vagy ?';
