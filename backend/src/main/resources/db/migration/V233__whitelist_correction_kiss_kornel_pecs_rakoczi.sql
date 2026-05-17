-- V233: Google login whitelist korrekciok
--
-- User-direktiva 2026-05-17 22:00: a Valutavalto rendszer Google login
-- whitelist-jenek finalisalt allapota.
--
-- Valtozasok:
--   1. UJ worker: Kiss Kornel (foertektaros, Kaposvar)
--      - code: G_KISS_KORNEL
--      - email: kornel.kiss.epc@gmail.com  (figyelem: .epc, NEM .ebc -
--        a user szandekosan hagyta ezt a domain-formatumot, hasonloan
--        a Fabulya/Hrabina/Veress .eec-vel)
--      - role: foertektar + ertektar
--
--   2. DEAKTIVALAS: G_PECS_RAKOCZI (Pecs Rakoczi Valuta, V179-ben seedelve
--      expressz.minibank.ertektar@gmail.com cimmel) - a user uj listajaban
--      NEM szerepel, valoszinuleg a Pecs Lacika (G_LACIKA_PECS) atvette
--      a teruletet.
--
-- Tovabb NEM valtozik a whitelist (24 worker erintetlen):
--   - KOSA, FABULYA, KASZA, BALI, BORSI (V162 + V179 hotfix-bol)
--   - G_DEKANY_TIMEA, G_SCHNELL_EDIT, G_KARDOS_ILDIKO
--   - G_HRABINA_KRISZTIAN, G_KENEZ_EVA, G_MADAR_ZOLTAN, G_GALLUSZ_ILDIKO
--   - G_MARCSIK_BRIGI, G_TV_KAPOSVAR, G_TV_PECS
--   - G_ET_BEKESCSABA, G_KOSZTYU_CSABA, G_ET_DEBRECEN, G_ET_NYIREGYHAZA
--   - G_ET_KECSKEMET, G_LACIKA_PECS, G_ET_SZEKSZARD
--   - G_SZEGED_ET, G_KAPOSVAR_ET
--   - (Juhasz Norbert mar V232-ben deaktivalva)

DO $$
DECLARE
    v_ebc_id UUID;
    v_default_branch_id UUID;
    v_kaposvar_branch_id UUID;
    v_default_password_hash CONSTANT TEXT := '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie';
BEGIN
    SELECT id INTO v_ebc_id FROM company WHERE code = 'EBC' LIMIT 1;
    IF v_ebc_id IS NULL THEN
        RAISE NOTICE 'V233: EBC ceg nem talalhato, migration kihagyva.';
        RETURN;
    END IF;

    -- Kaposvar branch (vagy default ha nincs)
    SELECT b.id INTO v_kaposvar_branch_id
      FROM branch b
     WHERE b.company_id = v_ebc_id
       AND (LOWER(b.code) LIKE '%kaposvar%' OR LOWER(b.city) LIKE '%kaposvar%')
     LIMIT 1;

    SELECT b.id INTO v_default_branch_id
      FROM branch b
     WHERE b.company_id = v_ebc_id
     ORDER BY CASE WHEN b.code = 'TISZA' THEN 0 ELSE 1 END, b.created_at
     LIMIT 1;

    IF v_default_branch_id IS NULL THEN
        RAISE NOTICE 'V233: EBC-nek nincs branch-e, migration kihagyva.';
        RETURN;
    END IF;

    -- ============================================================
    -- 1. KISS KORNEL UJ WORKER
    -- ============================================================
    INSERT INTO worker (
        company_id, branch_id, code, name, password_hash, role,
        is_active, email, google_login_enabled, created_at
    ) VALUES (
        v_ebc_id,
        COALESCE(v_kaposvar_branch_id, v_default_branch_id),
        'G_KISS_KORNEL',
        'Kiss Kornel',
        v_default_password_hash,
        'MANAGER',
        true,
        'kornel.kiss.epc@gmail.com',
        true,
        NOW()
    )
    ON CONFLICT (company_id, code) DO UPDATE SET
        email = EXCLUDED.email,
        is_active = true,
        google_login_enabled = true,
        name = EXCLUDED.name,
        branch_id = EXCLUDED.branch_id;

    -- Kiss Kornel role assignments: foertektar + ertektar
    INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
    SELECT w.id, r.id, true
      FROM worker w, worker_role_def r
     WHERE w.code = 'G_KISS_KORNEL'
       AND w.company_id = v_ebc_id
       AND r.code = 'foertektar'
    ON CONFLICT DO NOTHING;

    INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
    SELECT w.id, r.id, false
      FROM worker w, worker_role_def r
     WHERE w.code = 'G_KISS_KORNEL'
       AND w.company_id = v_ebc_id
       AND r.code = 'ertektar'
    ON CONFLICT DO NOTHING;

    -- ============================================================
    -- 2. G_PECS_RAKOCZI DEAKTIVALAS
    -- ============================================================
    UPDATE worker
       SET is_active = false,
           google_login_enabled = false,
           email = NULL,
           updated_at = NOW()
     WHERE company_id = v_ebc_id
       AND code = 'G_PECS_RAKOCZI';

    DELETE FROM worker_role_assignment
     WHERE worker_id = (
         SELECT id FROM worker
          WHERE company_id = v_ebc_id AND code = 'G_PECS_RAKOCZI'
     );

    -- ============================================================
    -- 3. BORSI TAMAS FOERTEKTAR ROLE HOZZAADAS
    -- ============================================================
    -- User-direktiva 2026-05-17 23:00: Borsi Tamas foertektar (V179-ben csak
    -- CASHIER role-ral szerepelt, role assignment nelkul).
    -- Eredmenyben: ertektar + foertektar canonical role, primary=ertektar.
    INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
    SELECT w.id, r.id, true
      FROM worker w, worker_role_def r
     WHERE w.code = 'BORSI'
       AND w.company_id = v_ebc_id
       AND r.code = 'ertektar'
    ON CONFLICT DO NOTHING;

    INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
    SELECT w.id, r.id, false
      FROM worker w, worker_role_def r
     WHERE w.code = 'BORSI'
       AND w.company_id = v_ebc_id
       AND r.code = 'foertektar'
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'V233: Whitelist korrekciok (Kiss Kornel +, Pecs Rakoczi -, Borsi foertektar +) lefutottak.';
END
$$;

-- Assertion: Kiss Kornel aktiv, Pecs Rakoczi inaktiv, Borsi foertektar
DO $$
DECLARE
    v_kiss_active INT;
    v_rakoczi_active INT;
    v_borsi_foertektar INT;
BEGIN
    SELECT COUNT(*) INTO v_kiss_active
      FROM worker w
      JOIN company c ON c.id = w.company_id
     WHERE c.code = 'EBC'
       AND w.code = 'G_KISS_KORNEL'
       AND w.is_active = true
       AND w.google_login_enabled = true;

    SELECT COUNT(*) INTO v_rakoczi_active
      FROM worker w
      JOIN company c ON c.id = w.company_id
     WHERE c.code = 'EBC'
       AND w.code = 'G_PECS_RAKOCZI'
       AND w.is_active = true;

    SELECT COUNT(*) INTO v_borsi_foertektar
      FROM worker w
      JOIN worker_role_assignment wra ON wra.worker_id = w.id
      JOIN worker_role_def r ON r.id = wra.role_def_id
      JOIN company c ON c.id = w.company_id
     WHERE c.code = 'EBC'
       AND w.code = 'BORSI'
       AND r.code = 'foertektar';

    IF v_kiss_active = 0 THEN
        RAISE EXCEPTION 'V233: Kiss Kornel NEM aktiv az EBC alatt!';
    END IF;

    IF v_rakoczi_active > 0 THEN
        RAISE EXCEPTION 'V233: Pecs Rakoczi meg mindig aktiv!';
    END IF;

    IF v_borsi_foertektar = 0 THEN
        RAISE EXCEPTION 'V233: BORSI nem kapott foertektar role-t!';
    END IF;

    RAISE NOTICE 'V233: Verifikalva - Kiss Kornel aktiv, Pecs Rakoczi inaktiv, Borsi foertektar.';
END
$$;
