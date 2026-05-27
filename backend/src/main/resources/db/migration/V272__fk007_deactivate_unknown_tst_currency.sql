-- V272 (FK-007): Ismeretlen 'TST' valutanem inaktiválása.
--
-- Beküldő: Kasza Helga (Főértéktár). A Békéscsaba Belváros pénztáron egy 'TST' kódú valutanem
-- jelent meg (19 valuta a többi kártya 18-ával szemben). A 'TST' NEM része a rendszer
-- valutatörzsének (egyetlen seed/migráció sem hozta létre — futásidőben, admin "új valuta"
-- funkcióval keletkezett teszt-rekord).
--
-- FK-006 elv (törlés helyett inaktiválás, jogszabályi megfelelőség + adatmegőrzés): a 'TST'
-- valutát is_active=false-ra állítjuk, NEM töröljük. Így:
--  - eltűnik minden aktív-valuta-vezérelt felületről (Országos készlet, árfolyam-nézet, dropdownok),
--  - a hozzá esetleg rögzített cash_balance / tranzakció adatok az adatbázisban érintetlenül megmaradnak
--    (visszanézhetők, auditálhatók).
--
-- Idempotens: ha a 'TST' nem létezik vagy már inaktív, a WHERE 0 sort érint (no-op).

UPDATE currency
   SET is_active = false, updated_at = NOW()
 WHERE code = 'TST'
   AND is_active = true;
