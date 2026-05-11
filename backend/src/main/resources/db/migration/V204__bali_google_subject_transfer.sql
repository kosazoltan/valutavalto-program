-- V204: BALI google_subject + google_linked_at atmasolasa W-S011-re.
--
-- Copilot P1 finding PR #554: V203 csak az email-t es a legacy mezokat
-- masolta at, de google_subject-et NEM. Ha BALI-nak volt Google login
-- binding (uq_worker_google_subject unique index), akkor:
--   1. findByGoogleSubject() az inaktiv BALI-t talalna meg
--   2. W-S011 soha nem tudna Google-lel belepni
--
-- Fix: BALI google_subject + google_linked_at atmasolasa W-S011-re,
-- BALI-n nullazas (unique constraint + clean deactivation).
-- Az egesz DO $$ block egyetlen tranzakcionkent fut (PostgreSQL DDL tx).

DO $$
DECLARE
    ebc_company_id UUID;
    bali_worker_id BIGINT;
    ws011_worker_id BIGINT;
    bali_google_subject TEXT;
    bali_google_linked_at TIMESTAMP;
BEGIN
    SELECT id INTO ebc_company_id FROM company WHERE code = 'EBC' LIMIT 1;
    IF ebc_company_id IS NULL THEN
        RAISE NOTICE 'V204: EBC ceg nem talalhato — migrate kihagyva.';
        RETURN;
    END IF;

    SELECT id INTO bali_worker_id FROM worker
    WHERE code = 'BALI' AND company_id = ebc_company_id LIMIT 1;

    SELECT id INTO ws011_worker_id FROM worker
    WHERE code = 'W-S011' AND company_id = ebc_company_id LIMIT 1;

    IF bali_worker_id IS NULL OR ws011_worker_id IS NULL THEN
        RAISE NOTICE 'V204: BALI vagy W-S011 worker nem talalhato — migrate kihagyva.';
        RETURN;
    END IF;

    -- 1. BALI google binding adatainak mentese
    SELECT google_subject, google_linked_at
    INTO bali_google_subject, bali_google_linked_at
    FROM worker WHERE id = bali_worker_id;

    -- Ha BALI-nak nincs google binding → nincs mit csinalni
    IF bali_google_subject IS NULL THEN
        RAISE NOTICE 'V204: BALI-nak nincs google_subject — nincs mit atmasolni.';
        RETURN;
    END IF;

    -- 2. BALI google binding nullazasa (uq_worker_google_subject constraint)
    UPDATE worker
    SET google_subject = NULL, google_linked_at = NULL
    WHERE id = bali_worker_id;

    -- 3. W-S011-re atmasolas (csak ha W-S011-nek meg nincs sajat Google binding)
    UPDATE worker
    SET google_subject = bali_google_subject,
        google_linked_at = bali_google_linked_at
    WHERE id = ws011_worker_id
      AND google_subject IS NULL;

    RAISE NOTICE 'V204: BALI google_subject (%) atmasolva W-S011-re.', bali_google_subject;
END
$$;
