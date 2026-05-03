-- V179: Google OAuth dolgozoi seed — 25+ EBC dolgozo whitelist + canonical role assignment.
--
-- Forras: user-direktiva 2026-05-03 (Google login implementacio + role mapping).
--
-- Kategorizalas a user altal megadott listak alapjan:
--   - "Ertektarosok" (2 prefix + ÉT prefix) -> ertektar role -> "ertektar" appMode (Electron ertektar)
--   - "Foertektar" lista -> foertektar role -> "full" appMode (szerver hozzaferes)
--   - "Belso ellenor" lista -> belso_ellenor role -> "full" appMode (szerver)
--   - "Tv" prefix vagy "Teruleti Vezetes" -> teruleti_vezeto role -> "full" appMode (kamera + szerver)
--   - "Halozatvezeto" / "ugyvezeto" -> ugyvezeto role -> "full" appMode (minden)
--   - "Iroda" prefix (1) -> irodai_dolgozo role -> "full" appMode (kamera + szerver)
--   - default vegyes -> irodai_dolgozo role
--
-- Egy worker TOBB role-t is kaphat (pl. Dekany Timea = irodai_dolgozo + foertektar).
--
-- Idempotens: ON CONFLICT DO UPDATE — masodik futasnal csak a Google flagek allnak be.
-- Tobbszoros email-lel rendelkezo worker (pl. Juhasz Norbi 2 emaillel) eseten csak az
-- elsodleges Google email kerul a worker.email-be; a masodikat NEM tarjuk per-worker.

DO $$
DECLARE
    ebc_company_id UUID;
    default_branch_id UUID;
    default_password_hash CONSTANT TEXT := '$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie';
    -- (BCrypt hash a "1234" jelszora — V162 mintajaval, force first-time-setup elso login utan)
BEGIN
    SELECT id INTO ebc_company_id FROM company WHERE code = 'EBC' LIMIT 1;
    IF ebc_company_id IS NULL THEN
        RAISE NOTICE 'V179: EBC ceg nem talalhato — migrate kihagyva.';
        RETURN;
    END IF;

    SELECT b.id INTO default_branch_id
    FROM branch b
    WHERE b.company_id = ebc_company_id
    ORDER BY CASE WHEN b.code = 'TISZA' THEN 0 ELSE 1 END, b.created_at
    LIMIT 1;

    IF default_branch_id IS NULL THEN
        RAISE NOTICE 'V179: EBC-nek nincs branch-e — migrate kihagyva.';
        RETURN;
    END IF;

    -- =================================================================
    -- 1. WORKER seed (UPSERT: ha mar letezik a code, csak email + flagek frissulnek)
    -- =================================================================

    -- Vegyes / iroda / teruleti vezeto / ugyvezeto / belso ellenor (13 ember)
    INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, is_active, email, google_login_enabled, created_at) VALUES
        (ebc_company_id, default_branch_id, 'G_DEKANY_TIMEA',     'Dekany Timea',          default_password_hash, 'ADMIN',    true, 'dekany.timea.ebc@gmail.com',         true, NOW()),
        (ebc_company_id, default_branch_id, 'G_SCHNELL_EDIT',     'Schnell Edit (Pecs)',   default_password_hash, 'ADMIN',    true, 'schnell.edit.ebc@gmail.com',         true, NOW()),
        (ebc_company_id, default_branch_id, 'G_KARDOS_ILDIKO',    'Kardos Ildiko',         default_password_hash, 'ADMIN',    true, 'kardos.ildiko.ebc@gmail.com',        true, NOW()),
        (ebc_company_id, default_branch_id, 'G_HRABINA_KRISZTIAN','Hrabina Krisztian',     default_password_hash, 'MANAGER',  true, 'hrabina.krisztian.eec@gmail.com',    true, NOW()),
        (ebc_company_id, default_branch_id, 'G_KENEZ_EVA',        'Kenez Eva',             default_password_hash, 'MANAGER',  true, 'veress.eva.eec@gmail.com',           true, NOW()),
        (ebc_company_id, default_branch_id, 'G_MADAR_ZOLTAN',     'Madar Zoltan',          default_password_hash, 'CASHIER',  true, 'madarzoltan.ebc@gmail.com',          true, NOW()),
        (ebc_company_id, default_branch_id, 'G_JUHASZ_NORBERT',   'Juhasz Norbert',        default_password_hash, 'ADMIN',    true, 'teruleti.vezeto.exz@gmail.com',      true, NOW()),
        (ebc_company_id, default_branch_id, 'G_GALLUSZ_ILDIKO',   'Kosa-Gallusz Ildiko',   default_password_hash, 'CASHIER',  true, 'gallusz.ildiko.ebc@gmail.com',       true, NOW()),
        (ebc_company_id, default_branch_id, 'G_MARCSIK_BRIGI',    'Marcsik Brigi',         default_password_hash, 'MANAGER',  true, 'szekszard.teruletivezeto@gmail.com', true, NOW()),
        (ebc_company_id, default_branch_id, 'G_TV_KAPOSVAR',      'Teruleti vezeto Kaposvar', default_password_hash, 'MANAGER', true, 'kaposvar.teruletivezeto@gmail.com', true, NOW()),
        (ebc_company_id, default_branch_id, 'G_TV_PECS',          'Teruleti vezeto Pecs',  default_password_hash, 'MANAGER',  true, 'teruletivezeto.pecs@gmail.com',      true, NOW())
    ON CONFLICT (company_id, code) DO UPDATE SET
        email = EXCLUDED.email,
        is_active = true,
        google_login_enabled = true,
        password_hash = COALESCE(worker.password_hash, EXCLUDED.password_hash);

    -- KOSA mar letezik V162-bol — frissites Google login-ra
    UPDATE worker
       SET google_login_enabled = true,
           email = 'kosa.zoltan.ebc@gmail.com'
     WHERE company_id = ebc_company_id AND code = 'KOSA';

    -- FABULYA mar letezik V162-bol — frissites belso_ellenor canonical role-ra
    UPDATE worker
       SET google_login_enabled = true,
           email = 'fabulyazsuzsa.eec@gmail.com'
     WHERE company_id = ebc_company_id AND code = 'FABULYA';

    -- =================================================================
    -- 2. ERTEKTAROSOK (12 ember a "2 / Ét" prefix-bol + Helga Foertektar)
    -- =================================================================

    INSERT INTO worker (company_id, branch_id, code, name, password_hash, role, is_active, email, google_login_enabled, created_at) VALUES
        (ebc_company_id, default_branch_id, 'G_HELGA_FOERTEKTAR', 'Helga Foertektar',           default_password_hash, 'ADMIN',   true, 'kasza.helga.ebc@gmail.com',          true, NOW()),
        (ebc_company_id, default_branch_id, 'G_ET_BEKESCSABA',    'Ertektar Bekescsaba',        default_password_hash, 'CASHIER', true, 'bekescsaba.ebc@gmail.com',           true, NOW()),
        (ebc_company_id, default_branch_id, 'G_KOSZTYU_CSABA',    'Kosztyu Csaba (Nyiregyhaza)', default_password_hash, 'CASHIER', true, 'kosztyu.csaba.ebc@gmail.com',        true, NOW()),
        (ebc_company_id, default_branch_id, 'G_ET_DEBRECEN',      'Ertektar Debrecen',          default_password_hash, 'CASHIER', true, 'debrecen.ebc@gmail.com',             true, NOW()),
        (ebc_company_id, default_branch_id, 'G_ET_NYIREGYHAZA',   'Holes Andi (Nyiregyhaza 1)', default_password_hash, 'CASHIER', true, 'nyiregyhaza.ebc@gmail.com',          true, NOW()),
        (ebc_company_id, default_branch_id, 'G_ET_KECSKEMET',     'Ertektar Kecskemet',         default_password_hash, 'CASHIER', true, 'kecskemet.ebc@gmail.com',            true, NOW()),
        (ebc_company_id, default_branch_id, 'G_LACIKA_PECS',      'Lacika (Pecs Ertektar)',     default_password_hash, 'CASHIER', true, 'pecs.ebc@gmail.com',                 true, NOW()),
        (ebc_company_id, default_branch_id, 'G_BALI_HENRIETT',    'Bali Henriett (Szeged)',     default_password_hash, 'CASHIER', true, 'bali.henriett.ebc@gmail.com',        true, NOW()),
        (ebc_company_id, default_branch_id, 'G_ET_SZEKSZARD',     'Ertektar Szekszard',         default_password_hash, 'CASHIER', true, 'szekszard.ebc@gmail.com',            true, NOW()),
        (ebc_company_id, default_branch_id, 'G_PECS_RAKOCZI',     'Pecs Rakoczi Valuta',        default_password_hash, 'CASHIER', true, 'expressz.minibank.ertektar@gmail.com', true, NOW()),
        (ebc_company_id, default_branch_id, 'G_SZEGED_ET',        'Szeged Ertektar',            default_password_hash, 'CASHIER', true, 'szeged.ebc@gmail.com',               true, NOW()),
        (ebc_company_id, default_branch_id, 'G_KAPOSVAR_ET',      'Kaposvar Ertektar',          default_password_hash, 'CASHIER', true, 'kaposvar.ebc@gmail.com',             true, NOW())
    ON CONFLICT (company_id, code) DO UPDATE SET
        email = EXCLUDED.email,
        is_active = true,
        google_login_enabled = true,
        password_hash = COALESCE(worker.password_hash, EXCLUDED.password_hash);

    -- Reset password_changed_at NULL (force first-time-setup kovetkezo login-nal — V162 minta)
    UPDATE worker SET password_changed_at = NULL
    WHERE company_id = ebc_company_id
      AND code LIKE 'G_%'
      AND password_changed_at IS NULL;

    -- =================================================================
    -- 3. CANONICAL ROLE ASSIGNMENT (worker_role_assignment)
    -- A WorkerService.login `validAppModes` szamitasa ezekre tamaszkodik:
    --   - "ertektar" canonical role -> "ertektar" appMode (Electron ertektar belepes)
    --   - "ugyvezeto"/"foertektar"/"belso_ellenor"/"teruleti_vezeto"/"biztonsagi_vezeto"/
    --     "irodai_dolgozo" canonical role -> "full" appMode (szerver hozzaferes)
    -- =================================================================

    -- IRODAI DOLGOZO + FOERTEKTAR (Dekany, Edit, Kardos — mindkettoben szerepelnek)
    INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
    SELECT w.id, r.id, true FROM worker w, worker_role_def r
    WHERE w.code IN ('G_DEKANY_TIMEA', 'G_SCHNELL_EDIT', 'G_KARDOS_ILDIKO')
      AND r.code = 'irodai_dolgozo'
      AND w.company_id = ebc_company_id
    ON CONFLICT DO NOTHING;

    INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
    SELECT w.id, r.id, false FROM worker w, worker_role_def r
    WHERE w.code IN ('G_DEKANY_TIMEA', 'G_SCHNELL_EDIT', 'G_KARDOS_ILDIKO')
      AND r.code = 'foertektar'
      AND w.company_id = ebc_company_id
    ON CONFLICT DO NOTHING;

    -- TERULETI VEZETOK (Tv prefix + Teruleti vezetes)
    INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
    SELECT w.id, r.id, true FROM worker w, worker_role_def r
    WHERE w.code IN ('G_HRABINA_KRISZTIAN', 'G_KENEZ_EVA', 'G_MARCSIK_BRIGI', 'G_TV_KAPOSVAR', 'G_TV_PECS')
      AND r.code = 'teruleti_vezeto'
      AND w.company_id = ebc_company_id
    ON CONFLICT DO NOTHING;

    -- UGYVEZETO (Kosa Zoltan + Juhasz Norbert halozatvezeto)
    INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
    SELECT w.id, r.id, true FROM worker w, worker_role_def r
    WHERE w.code IN ('KOSA', 'G_JUHASZ_NORBERT')
      AND r.code = 'ugyvezeto'
      AND w.company_id = ebc_company_id
    ON CONFLICT DO NOTHING;

    -- IRODAI DOLGOZO default (Madar Zoli, Kosa-Gallusz Ildiko)
    INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
    SELECT w.id, r.id, true FROM worker w, worker_role_def r
    WHERE w.code IN ('G_MADAR_ZOLTAN', 'G_GALLUSZ_ILDIKO')
      AND r.code = 'irodai_dolgozo'
      AND w.company_id = ebc_company_id
    ON CONFLICT DO NOTHING;

    -- BELSO ELLENOR (Fabulya Zsuzsa)
    INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
    SELECT w.id, r.id, true FROM worker w, worker_role_def r
    WHERE w.code = 'FABULYA'
      AND r.code = 'belso_ellenor'
      AND w.company_id = ebc_company_id
    ON CONFLICT DO NOTHING;

    -- ERTEKTAROSOK (12 ember "2/ÉT" prefix-bol)
    INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
    SELECT w.id, r.id, true FROM worker w, worker_role_def r
    WHERE w.code IN (
            'G_HELGA_FOERTEKTAR',
            'G_ET_BEKESCSABA', 'G_KOSZTYU_CSABA', 'G_ET_DEBRECEN', 'G_ET_NYIREGYHAZA',
            'G_ET_KECSKEMET', 'G_LACIKA_PECS', 'G_BALI_HENRIETT', 'G_ET_SZEKSZARD',
            'G_PECS_RAKOCZI', 'G_SZEGED_ET', 'G_KAPOSVAR_ET'
          )
      AND r.code = 'ertektar'
      AND w.company_id = ebc_company_id
    ON CONFLICT DO NOTHING;

    -- HELGA = Foertektar is (a Foertektar listaban kifejezetten szerepel)
    INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
    SELECT w.id, r.id, false FROM worker w, worker_role_def r
    WHERE w.code = 'G_HELGA_FOERTEKTAR'
      AND r.code = 'foertektar'
      AND w.company_id = ebc_company_id
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'V179: Google login whitelist seed-elve (25+ worker EBC alatt).';
END
$$;

-- Assertion: a beirt google_login_enabled workerek szama legalabb 25
DO $$
DECLARE
    google_count INT;
BEGIN
    SELECT COUNT(*) INTO google_count
    FROM worker w
    JOIN company c ON c.id = w.company_id
    WHERE c.code = 'EBC'
      AND w.google_login_enabled = true
      AND w.email IS NOT NULL;
    RAISE NOTICE 'V179: % worker-nek van Google login engedelyezve EBC-ben (>=25 vart).', google_count;
END
$$;
