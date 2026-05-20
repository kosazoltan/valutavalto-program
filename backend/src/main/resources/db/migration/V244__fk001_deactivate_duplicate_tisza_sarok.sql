-- V244: FK-001 — duplikált "Tisza Sarok" pénztár kivezetése (Kasza Helga, Főértéktár).
--
-- A rendszerben két pénztár szerepel ugyanarra a fizikai helyszínre: "Tisza Sarok" és
-- "Szeged Tisza Sarok". A megtartandó: "Szeged Tisza Sarok"; a "Tisza Sarok" kivezetendő.
--
-- BIZTONSÁGI ELVEK (Kósa Zoltán: csak 100%-ban működő, pénzügyi adatot NEM árvítunk):
--   1. NEM hard DELETE — a fiókra hivatkozó tranzakció-/audit-történet megőrzendő,
--      a hard DELETE FK-hibát okozna vagy történetet törölne. Helyette SOFT-DELETE
--      (is_active = false) → eltűnik az aktív Országos készlet nézetből.
--   2. CSAK akkor deaktiváljuk, ha a "Tisza Sarok"-nak NINCS nem-nulla kassza-egyenlege.
--      Ha van élő egyenleg, a fiók ÉRINTETLEN marad, és NOTICE jelzi, hogy előbb
--      ÁTVEZETÉS szükséges (átadás-átvétel a "Szeged Tisza Sarok"-ra) — az egyenleg
--      mozgatása KÖNYVELÉSI művelet (átadás-átvétel), NEM nyers SQL-merge.
-- Idempotens: ha nincs aktív "Tisza Sarok", nincs teendő.

DO $$
DECLARE
    v_dup_id  UUID;
    v_keep_id UUID;
    v_nonzero INT;
BEGIN
    SELECT id INTO v_dup_id  FROM branch WHERE name = 'Tisza Sarok'        AND is_active = true LIMIT 1;
    SELECT id INTO v_keep_id FROM branch WHERE name = 'Szeged Tisza Sarok'                      LIMIT 1;

    IF v_dup_id IS NULL THEN
        RAISE NOTICE 'FK-001: nincs aktív "Tisza Sarok" fiók — nincs teendő (idempotens).';
        RETURN;
    END IF;

    IF v_keep_id IS NULL THEN
        RAISE NOTICE 'FK-001: nincs "Szeged Tisza Sarok" (megtartandó) fiók — a duplikátum NEM lett deaktiválva, kézi ellenőrzés szükséges.';
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_nonzero
    FROM cash_balance
    WHERE branch_id = v_dup_id AND current_balance <> 0;

    IF v_nonzero > 0 THEN
        RAISE NOTICE 'FK-001: a "Tisza Sarok" még % nem-nulla valuta-egyenleget tartalmaz — '
                     'a fiók NEM lett deaktiválva. Előbb ÁT KELL VEZETNI az egyenleget a '
                     '"Szeged Tisza Sarok"-ra (átadás-átvétel), majd a fiók a BranchPage '
                     'admin felületen / következő deploykor deaktiválható.', v_nonzero;
        RETURN;
    END IF;

    UPDATE branch SET is_active = false WHERE id = v_dup_id;
    RAISE NOTICE 'FK-001: "Tisza Sarok" (%) deaktiválva (üres egyenleg). Megtartott: "Szeged Tisza Sarok" (%).', v_dup_id, v_keep_id;
END $$;
