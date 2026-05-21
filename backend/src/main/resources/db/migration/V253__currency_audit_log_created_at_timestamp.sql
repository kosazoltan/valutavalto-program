-- V253: currency_audit_log.created_at TIMESTAMPTZ -> TIMESTAMP (idozona nelkul).
--
-- ROOT CAUSE (2026-05-21, Borsi tesztelo bejelentes — POST /api/v1/currencies HTTP 500):
-- A V238 a created_at-ot TIMESTAMPTZ-kent hozta letre, a CurrencyAuditLog entity pedig
-- OffsetDateTime-kent mappelte. A @EnableJpaAuditing DEFAULT DateTimeProvider-e viszont
-- LocalDateTime-ot ad (a kodbazis konvencioja — pl. AuditLog.created_at is LocalDateTime +
-- TIMESTAMP). Igy az auditing LocalDateTime erteket nem lehetett az OffsetDateTime mezobe/
-- timestamptz oszlopba kotni → "Cannot convert ... LocalDateTime to OffsetDateTime" →
-- az auditRepository.save() dobott → a @Transactional createCurrency rollback-only lett →
-- a commit 500-zal elszallt (a writeAudit try/catch NEM mentett meg, mert a tranzakcio mar
-- rollback-only volt).
--
-- FIX: a DB-oszlopot a kodbazis-konvencionak megfeleloen TIMESTAMP-ra (idozona nelkul)
-- allitjuk, az entity mezo pedig LocalDateTime lett (lasd CurrencyAuditLog.java).
-- A tabla a hiba miatt URES (egyetlen currency-muvelet sem ment at), igy a tipus-valtas
-- adatvesztes-mentes. Idempotens guard: csak akkor alter, ha jelenleg timestamptz.

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'currency_audit_log'
           AND column_name = 'created_at'
           AND data_type = 'timestamp with time zone'
    ) THEN
        ALTER TABLE currency_audit_log
            ALTER COLUMN created_at TYPE TIMESTAMP(6) WITHOUT TIME ZONE
            USING created_at AT TIME ZONE 'UTC';
        ALTER TABLE currency_audit_log
            ALTER COLUMN created_at SET DEFAULT NOW();
        RAISE NOTICE 'V253: currency_audit_log.created_at TIMESTAMPTZ -> TIMESTAMP konvertalva.';
    ELSE
        RAISE NOTICE 'V253: currency_audit_log.created_at mar TIMESTAMP (vagy nincs) — no-op (idempotens).';
    END IF;
END $$;
