-- V158: vault_territory seed idempotency fix (Codex PR #125 P1 feedback)
--
-- Probléma: V156 elestt, ha egy ceg-nek inaktiv 'Fo Ertektar' rekordja volt
-- (is_active = false), akkor a WHERE NOT EXISTS feltetel aktiv-ra szur, atment
-- az ellenorzesen, majd az INSERT-bol a (company_id, name) unique constraint
-- miatt duplicate key error -> Flyway elestt.
--
-- Fix: ket lepesben csinaljuk idempotensen:
--   1. Reaktivalas: ha van inaktiv 'Fo Ertektar' es nincs mas aktiv territory,
--      aktivaljuk (ez megorzi az esetleges korábbi baseCapital ertekeket)
--   2. ON CONFLICT DO NOTHING: ha mas okbol mar van 'Fo Ertektar' ugyanavval a 
--      company_id, name kombi-val, ne kisertetkedjuk

-- 1. Reaktivalas: company-k, akiknek van inaktiv 'Fo Ertektar' de nincs aktiv
UPDATE vault_territory vt
SET is_active = true
WHERE vt.name = 'Fo Ertektar'
  AND vt.is_active = false
  AND NOT EXISTS (
      SELECT 1 FROM vault_territory vt2
      WHERE vt2.company_id = vt.company_id AND vt2.is_active = true
  );

-- 2. Biztonsagos INSERT: ON CONFLICT DO NOTHING a (company_id, name) unique-ra
--    (V156 ezzel a konstrukcioval robusztusabb lett volna)
INSERT INTO vault_territory (name, company_id, is_active, base_capital, base_capital_approved_at)
SELECT 'Fo Ertektar', c.id, true, 100000000.00, CURRENT_DATE
FROM company c
WHERE NOT EXISTS (
    SELECT 1
    FROM vault_territory vt
    WHERE vt.company_id = c.id
      AND vt.is_active = true
)
ON CONFLICT (company_id, name) DO NOTHING;

-- Ellenorzes: minden aktiv company-nak legalabb 1 aktiv territory-ja van
DO $$
DECLARE
    missing_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO missing_count
    FROM company c
    WHERE NOT EXISTS (
        SELECT 1 FROM vault_territory vt
        WHERE vt.company_id = c.id AND vt.is_active = true
    );
    IF missing_count > 0 THEN
        RAISE WARNING 'V158: Meg mindig % company nem rendelkezik aktiv vault_territory-val!', missing_count;
    ELSE
        RAISE NOTICE 'V158 vault_territory fix: minden ceg rendelkezik aktiv territory-val';
    END IF;
END $$;