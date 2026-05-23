# Legacy modul: MATREGEN

> Forrás (primer): `Anti/VALUTA/DLL/MATREGEN/MAKEDLL/Unit2.pas` (14571 karakter) · library: `DLL/MATREGEN/MAKEDLL/MATREGEN.DPR`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`matricaregeneralo`

## DFM form(ok) / képernyő
`TForm2`

**Feliratok/gombok (Caption):** KERESKEDELMI ADATOK REGENER

## Eljárások / függvények (.pas)
`FormActivate`, `Nulele`, `KILEPESTimer`, `ErtektartotalRegen`, `TradeParancs`, `ValutaParancs`, `TForm2.FormActivate`, `TForm2.Nulele`, `TForm2.KILEPESTimer`, `TForm2.ErtektarTotalRegen`, `TForm2.TradeParancs`, `TForm2.ValutaParancs`

## Érintett adatbázis-táblák
`HARDWARE`, `HAVIMAT`, `HAVIOSSZESITO`, `MATBIZONYLAT`, `MATDATA`, `NAPIMAT`, `NAPIOSSZESITO`, `PARAMETERS`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `DELETE FROM NAPIOSSZESITO WHERE DATUM=`
- `SELECT * FROM NAPIOSSZESITO`
- `SELECT * FROM`
- `WHERE DATUM=`
- `INSERT INTO NAPIOSSZESITO (DATUM,NYITO,TELEFON,MATRICA,VODAFON,`
- `DELETE FROM HAVIOSSZESITO`
- `WHERE EVHONAP=`
- `WHERE DATUM LIKE`
- `SELECT * FROM HAVIOSSZESITO`
- `INSERT INTO HAVIOSSZESITO (EVHONAP,NYITO,TELEFONFORINT,MATRICAFORINT,`
- `UPDATE PARAMETERS SET PILLALLAS=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- HIBA AZ E-KER ZÁRÓKÉSZLETÉBEN

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
