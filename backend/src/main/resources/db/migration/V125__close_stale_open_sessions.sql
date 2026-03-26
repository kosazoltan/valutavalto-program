-- V125: Close stale open sessions from previous days
-- Root cause: sessions opened on earlier dates were never closed (test/demo data),
-- blocking new session opening and buy/sell transactions.
UPDATE daily_session
SET status = 'CLOSED',
    closed_at = NOW(),
    closing_balance_huf = COALESCE(opening_balance_huf, 0)
WHERE status = 'OPEN'
  AND session_date < CURRENT_DATE;
