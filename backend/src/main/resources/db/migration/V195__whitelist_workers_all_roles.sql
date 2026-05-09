-- V195: Assign ALL canonical roles to the 5 whitelisted legacy workers.
-- User directive 2026-05-09: "mindenki kapja meg az osszes szerepkorhöz a hozzaferest"
-- BALI, BORSI, KASZA, KOSA, FABULYA — full role access.

DO $$
DECLARE
    ebc_company_id UUID;
    worker_codes TEXT[] := ARRAY['BALI', 'BORSI', 'KASZA', 'KOSA', 'FABULYA'];
    all_role_codes TEXT[] := ARRAY[
        'penztar', 'ertektar', 'ertekszallito',
        'foertektar', 'ugyvezeto', 'irodavezeto',
        'belso_ellenor', 'berszamfejto', 'penzugyi_vezeto',
        'irodai_dolgozo', 'csoportvezeto', 'arfolyam_nezo',
        'teruleti_vezeto', 'biztonsagi_vezeto'
    ];
    wcode TEXT;
    rcode TEXT;
BEGIN
    SELECT id INTO ebc_company_id FROM company WHERE code = 'EBC' LIMIT 1;
    IF ebc_company_id IS NULL THEN
        RAISE NOTICE 'V195: EBC ceg nem talalhato — migrate kihagyva.';
        RETURN;
    END IF;

    FOREACH wcode IN ARRAY worker_codes LOOP
        FOREACH rcode IN ARRAY all_role_codes LOOP
            INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
            SELECT w.id, r.id, false
            FROM worker w, worker_role_def r
            WHERE w.code = wcode
              AND r.code = rcode
              AND w.company_id = ebc_company_id
            ON CONFLICT (worker_id, role_def_id) DO NOTHING;
        END LOOP;
    END LOOP;

    RAISE NOTICE 'V195: 5 whitelisted worker (BALI, BORSI, KASZA, KOSA, FABULYA) — all 14 canonical roles assigned.';
END
$$;
