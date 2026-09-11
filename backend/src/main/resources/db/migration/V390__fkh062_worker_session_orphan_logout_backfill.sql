-- FKH-062: close orphaned open worker_session rows (logout_at backfill).
--
-- ROOT CAUSE (FKH-061, Defect C): WorkerService.logout() closed at most ONE open session row
-- (WorkerSessionRepository returned Optional), and when a worker had several open rows the
-- lookup threw IncorrectResultSizeDataAccessException -> HTTP 500 -> the row stayed open and the
-- next login added yet another open row. PR #1739 (432d858e) fixed the write path
-- (findByWorkerIdAndLogoutAtIsNull -> List, bulk close), but the rows that had already
-- accumulated were left untouched ("accepted risk" in the round-2 ruling). This migration is
-- that backfill.
--
-- MEASURED STATE (prod valuta, 2026-09-11):
--   SELECT count(*) FILTER (WHERE logout_at IS NULL) FROM worker_session;                -> 1533
--   total rows 1772, oldest login_at 2026-03-13 17:29:56, newest 2026-09-11 03:51:38
--   of the 1533 open rows, 1523 are SUPERSEDED (the same worker has a later login_at)
--   spread over 9 workers; the remaining 10 are each worker's most recent row.
--
-- DEFINITION OF "ORPHAN" (the only set this migration touches):
--   logout_at IS NULL AND EXISTS a later login_at for the SAME worker.
--   Such a row cannot represent a live session: the worker demonstrably started a new one.
--
-- VALUE WRITTEN: logout_at := the next login_at of the same worker.
--   This is DERIVED from data, not invented. It is the latest instant at which the session was
--   provably over, it is always > login_at, and it keeps every derived duration non-negative
--   (prod check: 0 closed rows with logout_at <= login_at today).
--   The alternatives are worse: NOW() would write a 2026-09 timestamp onto a March session
--   (fabricated 6-month sessions), and login_at itself would fabricate zero-length sessions.
--
-- DELIBERATELY NOT TOUCHED (scope):
--   * The 10 rows that are each worker's most recent open row. One of them may be a LIVE
--     session (prod: KASZA/BR035, login 2026-09-10 08:07), and for the rest there is no
--     evidence-backed end timestamp. The FKH-061 logout fix closes them on the next logout.
--   * worker_attendance (separate table, separate business meaning — working hours).
--   * audit_log: this repository's data-correction migrations deliberately write NO audit rows.
--     audit_log is append-only (triggers audit_log_no_update / audit_log_no_delete) and a direct
--     SQL INSERT would skip the H11 tamper-evidence hash chain built in
--     AuditLogService.applyHashChain — an unhashed row can never be repaired afterwards.
--
-- BLAST RADIUS: worker_session is read by WorkerSessionRepository only —
--   countActiveSessions (logoutAt IS NULL, 1 caller), findSessionsByDateRange (login_at based),
--   findByTokenId, findByWorkerIdAndLogoutAtIsNull (logout path). No money, no balance, no
--   accounting period is affected. Multi-tenant: the UPDATE is worker-scoped and company_id is
--   never rewritten, so tenant isolation is unchanged.
--
-- IDEMPOTENCY / FAIL-CLOSED: the UPDATE only ever selects rows with logout_at IS NULL and a
--   strictly later login for the same worker. A second run matches nothing. Rows whose state
--   does not match (already closed, or no later login) are left exactly as they are; the count
--   of every branch is reported through RAISE NOTICE and nothing raises, so a skipped correction
--   can never block a deployment.
--
-- VERIFICATION (run before and after):
--   SELECT count(*) FILTER (WHERE logout_at IS NULL) AS open_rows,
--          count(*) FILTER (WHERE logout_at IS NOT NULL AND logout_at <= login_at) AS invalid
--     FROM worker_session;
--   -- expected after: open_rows = one row per worker with an open session (prod: 10), invalid = 0

DO $$
DECLARE
    v_open_before  BIGINT;
    v_candidates   BIGINT;
    v_updated      BIGINT;
    v_invalid      BIGINT;
    v_open_after   BIGINT;
BEGIN
    SELECT count(*) FILTER (WHERE logout_at IS NULL) INTO v_open_before FROM worker_session;

    SELECT count(*) INTO v_candidates
      FROM worker_session s
     WHERE s.logout_at IS NULL
       AND EXISTS (SELECT 1 FROM worker_session s2
                    WHERE s2.worker_id = s.worker_id
                      AND s2.login_at > s.login_at);

    IF v_candidates = 0 THEN
        RAISE NOTICE 'V390: no superseded open worker_session rows (open=%) - nothing to do.',
                     v_open_before;
        RETURN;
    END IF;

    -- Absolute value per row, derived from the next login of the same worker.
    -- The logout_at IS NULL guard in the WHERE is also the optimistic-concurrency guard:
    -- if the application closed a row between the count above and this statement, it is skipped.
    WITH next_login AS (
        SELECT s.id,
               (SELECT min(s2.login_at)
                  FROM worker_session s2
                 WHERE s2.worker_id = s.worker_id
                   AND s2.login_at > s.login_at) AS closed_at
          FROM worker_session s
         WHERE s.logout_at IS NULL
    )
    UPDATE worker_session t
       SET logout_at = n.closed_at
      FROM next_login n
     WHERE t.id = n.id
       AND t.logout_at IS NULL
       AND n.closed_at IS NOT NULL
       AND n.closed_at > t.login_at;
    GET DIAGNOSTICS v_updated = ROW_COUNT;

    SELECT count(*) FILTER (WHERE logout_at IS NOT NULL AND logout_at <= login_at),
           count(*) FILTER (WHERE logout_at IS NULL)
      INTO v_invalid, v_open_after
      FROM worker_session;

    IF v_updated <> v_candidates THEN
        RAISE NOTICE 'V390: % of % superseded rows closed (the rest changed meanwhile) - '
                     'open rows now %.', v_updated, v_candidates, v_open_after;
    ELSE
        RAISE NOTICE 'V390: % orphaned worker_session rows closed at the next login of the same '
                     'worker (open % -> %).', v_updated, v_open_before, v_open_after;
    END IF;

    IF v_invalid > 0 THEN
        RAISE NOTICE 'V390: WARNING - % closed rows have logout_at <= login_at; '
                     'manual investigation required (not created by this migration).', v_invalid;
    END IF;
END $$;
