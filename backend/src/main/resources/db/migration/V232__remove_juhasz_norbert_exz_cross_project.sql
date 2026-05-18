-- V232: Juhasz Norbert worker DEAKTIVALASA - cross-project leak fix
--
-- HIBA forrasa: V179__google_login_employee_seed.sql seed-elte be a G_JUHASZ_NORBERT
-- workert az EBC (Valutavalto) ceg ala, DE az email-je 'teruleti.vezeto.exz@gmail.com'
-- volt - vagyis EXZ (Exclusive Zalogház) domainű cím. Cross-project copy-paste hiba.
--
-- User-direktiva 2026-05-17: "Juhasz Norbertnek nincs koze a valutavalto programhoz."
-- Tehat a worker bejegyzes deaktivalando az EBC alol (NEM toroljuk - audit + ON CONFLICT
-- biztonsag erdekeben), de a Google login es az aktivitas vissza-allitva.
--
-- A 'kosa.zoltan.ebc@gmail.com' ugyvezeto egyedul tudjon a Halozatvezeto / Ugyvezeto
-- szerepkort betolteni; Juhasz Norbert NEM kell.

DO $$
DECLARE
    v_ebc_id UUID;
    v_juhasz_id BIGINT;  -- HOTFIX: worker.id BIGSERIAL/BIGINT, NEM UUID
BEGIN
    SELECT id INTO v_ebc_id FROM company WHERE code = 'EBC' LIMIT 1;
    IF v_ebc_id IS NULL THEN
        RAISE NOTICE 'V232: EBC company nem talalhato, migration kihagyva.';
        RETURN;
    END IF;

    SELECT id INTO v_juhasz_id
    FROM worker
    WHERE company_id = v_ebc_id AND code = 'G_JUHASZ_NORBERT'
    LIMIT 1;

    IF v_juhasz_id IS NULL THEN
        RAISE NOTICE 'V232: G_JUHASZ_NORBERT nincs az EBC-ben (esetleg mar manualisan torolve).';
        RETURN;
    END IF;

    -- Deaktivalas + Google login letiltas + email kinullazas (cross-project email eltavolitva)
    UPDATE worker
       SET is_active = false,
           google_login_enabled = false,
           email = NULL,
           updated_at = NOW()
     WHERE id = v_juhasz_id;

    -- ugyvezeto role assignment torlese (V179-ben kapta)
    DELETE FROM worker_role_assignment
     WHERE worker_id = v_juhasz_id;

    RAISE NOTICE 'V232: G_JUHASZ_NORBERT (Juhasz Norbert) deaktivalva - cross-project EXZ email eltavolitva.';
END
$$;

-- Assertion: a G_JUHASZ_NORBERT worker NEM aktiv tobbe EBC alatt
DO $$
DECLARE
    v_active_count INT;
BEGIN
    SELECT COUNT(*) INTO v_active_count
    FROM worker w
    JOIN company c ON c.id = w.company_id
    WHERE c.code = 'EBC'
      AND w.code = 'G_JUHASZ_NORBERT'
      AND w.is_active = true;

    IF v_active_count > 0 THEN
        RAISE EXCEPTION 'V232: G_JUHASZ_NORBERT meg mindig aktiv az EBC alatt! count=%', v_active_count;
    END IF;

    RAISE NOTICE 'V232: Verifikalva - G_JUHASZ_NORBERT inaktiv EBC alatt.';
END
$$;
