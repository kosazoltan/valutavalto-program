-- V364: FK-066 — pénznemenkénti záráskori tolerancia seed (insert-if-missing)
--
-- Szerződés (FK-066 GREEN-fázis, user-döntés 2026-07-27):
--  * GLOBÁLIS (company_id IS NULL) explicit sorok: HUF=5 (Ft), EUR=1, USD=1.
--    Cég-szintű felülírás a SystemParameterService findEffective mechanizmusán át
--    (parameter_key + company_id sor) — ehhez külön seed nem kell.
--  * SEED-DÖNTÉS: a V307-mintától SZÁNDÉKOSAN eltérve NINCS update-if-different ág —
--    az üzemeltető által testre szabott toleranciát redeploy nem írhatja felül némán.
--  * Operátor-szemantika (ClosingTolerance.blocks): explicit sor → |diff| >= érték
--    blokkol; sor hiányában kód-fallback (HUF→1, nem-HUF→0) → |diff| > érték blokkol.
--
-- Idempotens: insert-if-missing, a V307 INSERT-ágának mintájára (NOT-EXISTS-őrfeltétellel).

INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
SELECT gen_random_uuid(), 'CLOSING_TOLERANCE_HUF', '5', 'NUMBER', 'CLOSING',
       'FK-066: záráskori eltérés-tolerancia HUF-ra (Ft). Explicit sor: |eltérés| >= érték blokkol '
       || '(magyarázat nélkül); a sor törlése esetén a kód-fallback él (1 Ft, |eltérés| > érték).',
       true
WHERE NOT EXISTS (
    -- Codex M2 fix: a GLOBÁLIS sor hiányát nézzük (V348-minta) — egy meglévő CÉGES
    -- override nem nyomhatja el a globális seedet.
    SELECT 1 FROM system_parameter
     WHERE parameter_key = 'CLOSING_TOLERANCE_HUF' AND company_id IS NULL
);

INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
SELECT gen_random_uuid(), 'CLOSING_TOLERANCE_EUR', '1', 'NUMBER', 'CLOSING',
       'FK-066: záráskori eltérés-tolerancia EUR-ra (EUR egység). Explicit sor: |eltérés| >= érték '
       || 'blokkol (magyarázat nélkül); a sor törlése esetén a kód-fallback él (0, darabra pontos).',
       true
WHERE NOT EXISTS (
    SELECT 1 FROM system_parameter
     WHERE parameter_key = 'CLOSING_TOLERANCE_EUR' AND company_id IS NULL
);

INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
SELECT gen_random_uuid(), 'CLOSING_TOLERANCE_USD', '1', 'NUMBER', 'CLOSING',
       'FK-066: záráskori eltérés-tolerancia USD-re (USD egység). Explicit sor: |eltérés| >= érték '
       || 'blokkol (magyarázat nélkül); a sor törlése esetén a kód-fallback él (0, darabra pontos).',
       true
WHERE NOT EXISTS (
    SELECT 1 FROM system_parameter
     WHERE parameter_key = 'CLOSING_TOLERANCE_USD' AND company_id IS NULL
);
