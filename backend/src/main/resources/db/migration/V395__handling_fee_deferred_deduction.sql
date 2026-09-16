-- V395 (SEC-001 / FKH-071 follow-up): deferred deduction of handling-fee corrections.
--
-- Context: a reversal or a downward supervisor fee override CORRECTS money that was already
-- booked into the transaction row, the cash balance and the audit log inside the same database
-- transaction. The strict decrease() (FKH-071 FR-7) throws when the drawer holds less than the
-- fee, which rolled the whole storno back for any branch that had handed its drawer to the vault
-- via a KK shipment.
--
-- Clamping alone loses money truth: the FR-5 cancellation of that KK shipment later restores its
-- full amount, so a clamped-away reversal would leave a phantom balance
-- (+290 transaction, -290 shipment, -0 reversal, +290 cancellation = 290 instead of 0).
-- The uncovered part of a correction is therefore PERSISTED here and offset against the next
-- increase, so the rolled balance converges to the value the fee history implies.
--
-- NOT NULL with a DEFAULT is safe on this table: it is FKH-071-new (V394) and starts empty.

ALTER TABLE handling_fee_balance
    ADD COLUMN IF NOT EXISTS deferred_deduction NUMERIC(18,2) NOT NULL DEFAULT 0;

ALTER TABLE handling_fee_balance
    DROP CONSTRAINT IF EXISTS chk_hfb_deferred_nonnegative;

ALTER TABLE handling_fee_balance
    ADD CONSTRAINT chk_hfb_deferred_nonnegative CHECK (deferred_deduction >= 0);

COMMENT ON COLUMN handling_fee_balance.deferred_deduction IS
    'SEC-001 (V395): the part of a correction (reversal / downward fee override) that the drawer '
    'could not cover. Offset against the next increase before it reaches current_balance. '
    'Always >= 0; current_balance stays >= 0.';
