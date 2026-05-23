# Legacy modul: CONFIDEN

> Forrás (primer): `Anti/VALUTA/DLL/CONFIDEN/MAKEDLL/Unit2.pas` (7443 karakter) · library: `DLL/CONFIDEN/MAKEDLL/Confi.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`confidentreport`

## DFM form(ok) / képernyő
`TForm2`

**Feliratok/gombok (Caption):** Form2 · A FENTI K · AZ AL · BIZALMAS BEJELENT

## Eljárások / függvények (.pas)
`NOKULDOGOMBClick`, `AlapadatBeolvasas`, `Kitkod`, `KULDOGOMBClick`, `FormActivate`, `TForm2.FormActivate`, `TForm2.KULDOGOMBClick`, `TForm2.Kitkod`, `TForm2.Alapadatbeolvasas`, `TForm2.NOKULDOGOMBClick`

## Érintett adatbázis-táblák
`HARDWARE`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`

## Felhasználói üzenetek (üzleti szabály-jelek)
- AZ ADATOK BEKÜLDÉSE SIKERTELEN
- AZ ADATOK SIKERESEN BEKÜLDVE

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
