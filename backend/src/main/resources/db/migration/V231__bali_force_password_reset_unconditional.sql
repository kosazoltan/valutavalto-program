-- V231: BALI password_hash NULL — UNCONDITIONAL (defensive)
--
-- User-jelentes 2026-05-15 v2.5.53 telepito utan: A V230-as fix ellenere is
-- "A jelenlegi jelszo nem egyezik" hibat dob a SetupWizard step 5.
--
-- LEHETSEGES OKOK:
-- 1. V230 csak is_active=TRUE workereket erinti. Ha BALI valamiert inaktiv
--    allapotba kerult, V230 atugorta.
-- 2. Tobb BALI worker letezhet (multi-tenant).
-- 3. A SetupWizard valamilyen okbol mas worker-t kuld be.
--
-- DEFENSIVE V231: drop is_active filter, reactivate + NULL password fields.
-- Ket lepesben: (1) reactivate BALI ha esetleg inaktiv, (2) NULL password.

DO $$
DECLARE
    ebc_company_id UUID;
    affected_count INT;
BEGIN
    SELECT id INTO ebc_company_id FROM company WHERE code = 'EBC' LIMIT 1;
    IF ebc_company_id IS NULL THEN
        RAISE NOTICE 'V231: EBC ceg nem letezik, migration kihagyva.';
        RETURN;
    END IF;

    -- 1. Reactivate BALI (idempotens, biztos hogy aktiv legyen)
    UPDATE worker
    SET is_active = TRUE
    WHERE code = 'BALI'
      AND company_id = ebc_company_id;
    GET DIAGNOSTICS affected_count = ROW_COUNT;
    RAISE NOTICE 'V231: BALI reactivate, rows=%', affected_count;

    -- 2. NULL password_hash + password_changed_at — UNCONDITIONAL, drop is_active filter
    UPDATE worker
    SET password_hash = NULL,
        password_changed_at = NULL
    WHERE code = 'BALI'
      AND company_id = ebc_company_id;
    GET DIAGNOSTICS affected_count = ROW_COUNT;
    RAISE NOTICE 'V231: BALI password fields NULL, rows=%', affected_count;

    -- 3. Verify
    PERFORM 1 FROM worker
    WHERE code = 'BALI'
      AND company_id = ebc_company_id
      AND is_active = TRUE
      AND password_hash IS NULL
      AND password_changed_at IS NULL;
    IF NOT FOUND THEN
        RAISE WARNING 'V231: BALI worker NEM allt at a kivant allapotba — kerem ellenorizze a worker tablat manualisan.';
    ELSE
        RAISE NOTICE 'V231: BALI worker most: active=TRUE, password_hash=NULL, password_changed_at=NULL. SetupWizard "elso telepites"-kent fogja kezelni.';
    END IF;
END$$;
