-- FK-036 (2026-06-20): BR020 "Szeged Ertektar" hibas cash_balance sorainak torlese.
--
-- GYOKEROK: a V247 (fk_worker_dedup_and_balance_consolidation) a deaktivalt KORUT penztar
-- egyenleget (HUF/EUR/USD) nyers SQL-lel tevesen a BR020 (is_vault=TRUE) branch-be rakta at.
-- Egy ertektar (is_vault=TRUE) branch-nek NEM szabad cash_balance (penztar-kassza) sora legyen:
-- az ertektar-keszlet helyesen a currency_stock / vault_territory utvonalon el (V323/V326/V332/V333).
-- Ezert ezek a cash_balance sorok redundans, hibas adat, amelyek beszivarogtak az Orszagos keszlet
-- (penztar) nezetbe es a "X penztar" szamlalo 65 helyett 66-ot mutatott.
--
-- HATAS: a megjelenitesi hibat a backend service-szintu szuro (InventoryService.getAllStock
-- activeNonVaultBranch predikatum, FK-036) onmagaban megszunteti; ez a migracio a redundans
-- sorok TENYLEGES ADAT-TAKARITASA (defense-in-depth + a hibas tortenelmi adat eltavolitasa).
--
-- SCOPE / BIZTONSAG: kizarolag is_vault=TRUE ES is_active=TRUE ES company.code='EBC' branch-ek
-- cash_balance sorait torli. Mas branch, mas ceg, inaktiv branch NEM erintett. A currency_stock,
-- branch, vault_territory, audit_log tablak ERINTETLENEK maradnak (csak cash_balance DELETE).
--
-- ELLENORZO SELECT (a torles ELOTT futtathato; varhato eredmeny: pontosan a BR020 branch sorai):
--   SELECT b.code, b.name, b.is_vault, COUNT(cb.id) AS cash_balance_rows
--   FROM branch b
--   JOIN cash_balance cb ON cb.branch_id = b.id
--   JOIN company c ON c.id = b.company_id
--   WHERE c.code = 'EBC' AND b.is_vault = TRUE AND b.is_active = TRUE
--   GROUP BY b.code, b.name, b.is_vault;

DELETE FROM cash_balance
WHERE branch_id IN (
    SELECT b.id
    FROM branch b
    JOIN company c ON c.id = b.company_id
    WHERE c.code = 'EBC'
      AND b.is_vault = TRUE
      AND b.is_active = TRUE
);
