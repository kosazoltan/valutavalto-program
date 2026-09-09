-- FKH-059 review follow-up (chatgpt-codex P1): the three FKH058_TEST_DATA_PURGE rows
-- were inserted by direct SQL, so they carry no H11 tamper-evidence chain hash, and
-- audit_log is strictly append-only (triggers audit_log_no_update / audit_log_no_delete),
-- which makes a backfill UPDATE impossible by design.
-- Resolution: append ONE annex row that IS part of the chain and names the three
-- unhashed rows, so the chain covers the purge from this point on and the gap is
-- self-documented instead of silent.
-- Hash formula mirrors AuditLogService.applyHashChain (AuditLogService.java:205-230);
-- verified byte-identical against 5 existing prod rows before running.
\set ON_ERROR_STOP on
BEGIN;

DO $$
DECLARE
    prev     text;
    ids      text;
    content  text;
    new_id   uuid := gen_random_uuid();
BEGIN
    IF EXISTS (SELECT 1 FROM audit_log WHERE action = 'FKH058_TEST_DATA_PURGE_CHAIN_ANNEX') THEN
        RAISE NOTICE 'FKH-059: annex row already present, nothing to do';
        RETURN;
    END IF;

    SELECT string_agg(id::text, ', ' ORDER BY branch_name) INTO ids
      FROM audit_log WHERE action = 'FKH058_TEST_DATA_PURGE';

    IF ids IS NULL THEN
        RAISE NOTICE 'FKH-059: no FKH058_TEST_DATA_PURGE rows found, nothing to annex';
        RETURN;
    END IF;

    SELECT a.entry_hash INTO prev
      FROM audit_log a WHERE a.entry_hash IS NOT NULL
     ORDER BY a.created_at DESC LIMIT 1;

    content := concat_ws('|',
        'FKH058_TEST_DATA_PURGE_CHAIN_ANNEX',
        'AuditLog',
        new_id::text,
        'developer-dba',
        'Chain annex for direct-SQL purge rows: ' || ids,
        '',
        'CHAIN_ANNEX',
        coalesce(prev, ''));

    INSERT INTO audit_log (id, action, entity_type, entity_id, created_at, ts,
                           company_id, user_id, user_name, worker_role, reason,
                           changes, new_value, previous_hash, entry_hash)
    VALUES (new_id,
            'FKH058_TEST_DATA_PURGE_CHAIN_ANNEX',
            'AuditLog',
            new_id::text,
            NOW(), NOW(),
            '17015396-a878-4677-ab8e-05f2f7a8ee6c',
            'developer-dba', 'Fejleszto/DBA', 'DEVELOPER',
            'FKH-059: H11 chain annex — the referenced FKH058_TEST_DATA_PURGE rows were written by direct SQL and carry no entry_hash; audit_log is append-only so they cannot be backfilled',
            'Chain annex for direct-SQL purge rows: ' || ids,
            'CHAIN_ANNEX',
            prev,
            encode(sha256(convert_to(content, 'UTF8')), 'hex'));
END $$;

SELECT action, left(previous_hash, 16) AS prev16, left(entry_hash, 16) AS hash16, created_at
  FROM audit_log
 WHERE action IN ('FKH058_TEST_DATA_PURGE', 'FKH058_TEST_DATA_PURGE_CHAIN_ANNEX')
 ORDER BY created_at, action;

COMMIT;
