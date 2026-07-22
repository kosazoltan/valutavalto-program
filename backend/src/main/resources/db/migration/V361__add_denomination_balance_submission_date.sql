ALTER TABLE denomination_balance
    ADD COLUMN IF NOT EXISTS submission_date DATE;

UPDATE denomination_balance
   SET submission_date = COALESCE(updated_at::date, CURRENT_DATE)
 WHERE submission_date IS NULL;

ALTER TABLE denomination_balance
    ALTER COLUMN submission_date SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_denom_balance_submission
    ON denomination_balance (cash_desk_id, submission_date, denomination_category);
