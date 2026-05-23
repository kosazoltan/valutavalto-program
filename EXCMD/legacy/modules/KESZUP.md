# Legacy modul: KESZUP

> Forrás (primer): `Anti/VALUTA/DLL/KESZUP/MAKEDLL/Unit2.pas` (20286 karakter) · library: `DLL/KESZUP/MAKEDLL/KESZUP.DPR`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`pillkeszletbekuldo`

## DFM form(ok) / képernyő
`TKESZLETBEKULDO`

**Feliratok/gombok (Caption):** 0i · AZ AKTU

## Eljárások / függvények (.pas)
`FormActivate`, `Adatmeghatarozas`, `KeszletFeliras`, `Napiforgalom`, `Aktualkeszletek`, `Nulele`, `Keszletkod`, `DnemKod`, `KILEPOTimer`, `ValutaParancs`, `Nul3`, `Scandnem`, `TKESZLETBEKULDO.FormActivate`, `TKESZLETBEKULDO.KeszletFeliras`, `TKeszletBekuldo.Nul3`, `TKESZLETBEKULDO.DnemKod`, `TKESZLETBEKULDO.Keszletkod`, `TKESZLETBEKULDO.kilepoTimer`, `TKeszletbekuldo.Scandnem`, `TKeszletbekuldo.ValutaParancs`, `TKeszletBekuldo.AdatMeghatarozas`, `TKeszletbekuldo.Napiforgalom`, `TKeszletBekuldo.AktualKeszletek`, `TKeszletBekuldo.Nulele`

## Érintett adatbázis-táblák
`ARFOLYAM`, `BLOKKTETEL`, `FOGLALOKESZLET`, `HARDWARE`, `KEZELESIDATA`, `MATDATA`, `PARAMETERS`, `PENZTAR`, `WUAFAADATOK`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `UPDATE HARDWARE SET BKKS=`
- `SELECT * FROM WUAFAADATOK`
- `SELECT * FROM FOGLALOKESZLET`
- `SELECT * FROM PARAMETERS`
- `SELECT * FROM MATDATA`
- `SELECT * FROM BLOKKTETEL`
- `WHERE STORNO=1`
- `SELECT * FROM`
- `WHERE (STORNO=1) AND (DATUM=`
- `SELECT * FROM ARFOLYAM`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
