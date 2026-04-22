-- V156: vault_territory default seed minden company-nek, akinek meg nincs aktiv territory.
--
-- Ok: a VaultBankTransactionService.createBankTransaction "Nincs aktiv ertektari terulet!"
-- hibaval elbukik, ha a company-nak nincs leglabb egy aktiv vault_territory rekordja.
-- Ez blokkolja a banki koteseket. Ez a seed garantalja, hogy minden ceg tud banki
-- tranzakciot futtatni out-of-the-box.
--
-- Biztonsag: a unique constraint (company_id, name) miatt duplikacio kizart.
-- Ha a company-nak mar van aktiv territory (bármilyen névvel), ez a sor nem insert.
--
-- Base capital default: 100 000 000 Ft (100 MFt) — tipikus foertektari alapitoke.
-- A user kesobb modosithatja admin UI-on vagy SQL-lel.

INSERT INTO vault_territory (name, company_id, is_active, base_capital, base_capital_approved_at)
SELECT 'Fo Ertektar', c.id, true, 100000000.00, CURRENT_DATE
FROM company c
WHERE NOT EXISTS (
    SELECT 1
    FROM vault_territory vt
    WHERE vt.company_id = c.id
      AND vt.is_active = true
);

-- Ellenorzes: log, hany company-nek lett seed-elve
DO $$
DECLARE
    seeded_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO seeded_count
    FROM vault_territory
    WHERE name = 'Fo Ertektar'
      AND base_capital_approved_at = CURRENT_DATE;
    RAISE NOTICE 'V156 vault_territory seed: % uj rekord', seeded_count;
END $$;