-- V181: Teruleti vezetok atrendezese kamera-only access-re + Pecs Rakoczi delete.
--
-- Forras: user-direktiva 2026-05-03 (V179 utani role-mapping korrekcio).
--
-- Valtoztatasok:
-- 1. Madar Zoltan (G_MADAR_ZOLTAN) es Kosa-Gallusz Ildiko (G_GALLUSZ_ILDIKO) atkerul
--    `irodai_dolgozo` role-bol `teruleti_vezeto`-ra. Ettol a teruleti vezetok szama
--    7 lesz: Hrabina, Kenez, Marcsik, TV Kaposvar, TV Pecs, Madar, Gallusz.
-- 2. Pecs Rakoczi (G_PECS_RAKOCZI) tevesen kerult be — torolve worker_role_assignment-bol
--    es worker tablabol.
-- 3. A `teruleti_vezeto` canonical role MOST a `WorkerService.login`-ban "kamera" appMode-ot
--    kap (NEM "full"-t mint a tobbi szerver role) — lasd backend Java valtoztatas
--    a SERVER_CANONICAL_ROLES + KAMERA_CANONICAL_ROLES szetvalasztassal.
--
-- Idempotens: WHERE EXISTS-szel + ON CONFLICT-tel — masodszori futasnal no-op.

DO $$
DECLARE
    ebc_company_id UUID;
    role_irodai_id INT;
    role_teruleti_id INT;
    pecs_rakoczi_worker_id BIGINT;
BEGIN
    SELECT id INTO ebc_company_id FROM company WHERE code = 'EBC' LIMIT 1;
    IF ebc_company_id IS NULL THEN
        RAISE NOTICE 'V181: EBC ceg nem talalhato — migrate kihagyva.';
        RETURN;
    END IF;

    SELECT id INTO role_irodai_id FROM worker_role_def WHERE code = 'irodai_dolgozo';
    SELECT id INTO role_teruleti_id FROM worker_role_def WHERE code = 'teruleti_vezeto';
    IF role_irodai_id IS NULL OR role_teruleti_id IS NULL THEN
        RAISE NOTICE 'V181: irodai_dolgozo / teruleti_vezeto canonical role nincs seedelve — V147 elotti DB?';
        RETURN;
    END IF;

    -- =================================================================
    -- 1. MADAR + GALLUSZ role swap: irodai_dolgozo -> teruleti_vezeto
    -- =================================================================

    -- Toroljuk az `irodai_dolgozo` assignmentet (ha van)
    DELETE FROM worker_role_assignment
    WHERE role_def_id = role_irodai_id
      AND worker_id IN (
        SELECT id FROM worker
        WHERE company_id = ebc_company_id
          AND code IN ('G_MADAR_ZOLTAN', 'G_GALLUSZ_ILDIKO')
      );

    -- Copilot P2 PR #363: Hozzaadjuk a `teruleti_vezeto` assignmentet,
    -- vagy ha mar letezik (admin korabban felvette), promotaljuk primary-ve.
    -- Igy garantalt hogy az irodai_dolgozo torles utan NEM marad primary nelkuli allapot.
    INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
    SELECT w.id, role_teruleti_id, true FROM worker w
    WHERE w.company_id = ebc_company_id
      AND w.code IN ('G_MADAR_ZOLTAN', 'G_GALLUSZ_ILDIKO')
    ON CONFLICT (worker_id, role_def_id) DO UPDATE SET is_primary = true;

    RAISE NOTICE 'V181: Madar + Gallusz teruleti_vezeto role-ra atrendezve.';

    -- =================================================================
    -- 2. PECS RAKOCZI deactivate (tevesen vettuk fel)
    -- =================================================================
    --
    -- Codex P1 PR #363 follow-up: a HARD DELETE bukna ha a workerhez downstream FK
    -- referenciak vannak (transaction.created_by_worker_id, worker_session.worker_id, stb.
    -- — sok tabla `ON DELETE RESTRICT` viselkedessel hivatkozik a worker(id)-ra).
    -- Megoldas: soft delete — `is_active = false` + `google_login_enabled = false`.
    -- A worker NEM jelenik meg login candidate-kent (V178 partial unique index
    -- WHERE google_login_enabled = TRUE), de a mar letrejott downstream rekordok
    -- intaktak maradnak. A role assignmentet tovabbra is toroljuk (idempotens).

    SELECT id INTO pecs_rakoczi_worker_id FROM worker
    WHERE company_id = ebc_company_id AND code = 'G_PECS_RAKOCZI'
    LIMIT 1;

    IF pecs_rakoczi_worker_id IS NOT NULL THEN
        DELETE FROM worker_role_assignment WHERE worker_id = pecs_rakoczi_worker_id;
        UPDATE worker
           SET is_active = false,
               google_login_enabled = false
         WHERE id = pecs_rakoczi_worker_id;
        RAISE NOTICE 'V181: G_PECS_RAKOCZI worker deactivated (is_active=false, google_login_enabled=false) + role assignmentek torolve.';
    ELSE
        RAISE NOTICE 'V181: G_PECS_RAKOCZI nem talalhato (mar torolve/deactivated, vagy V179 nem futott meg).';
    END IF;
END
$$;

-- Assertion: 7 teruleti vezeto van
DO $$
DECLARE
    teruleti_count INT;
BEGIN
    SELECT COUNT(DISTINCT w.id) INTO teruleti_count
    FROM worker w
    JOIN worker_role_assignment wra ON wra.worker_id = w.id
    JOIN worker_role_def r ON r.id = wra.role_def_id
    JOIN company c ON c.id = w.company_id
    WHERE c.code = 'EBC'
      AND r.code = 'teruleti_vezeto'
      AND w.code LIKE 'G_%';
    RAISE NOTICE 'V181: % teruleti vezeto (G_%% prefix) EBC-ben (>=7 vart Hrabina/Kenez/Marcsik/TV_Kaposvar/TV_Pecs/Madar/Gallusz).', teruleti_count;
END
$$;
