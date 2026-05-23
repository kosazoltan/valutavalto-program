# Legacy modul: MATPTAR

> Forrás (primer): `Anti/VALUTA/DLL/MATPTAR/MAKEDLL/Unit2.pas` (24404 karakter) · library: `DLL/MATPTAR/MAKEDLL/Matptar.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`matpenztarrutin`

## DFM form(ok) / képernyő
`TMATPENZTAR`

**Feliratok/gombok (Caption):** MATPENZTAR · ELEKTROMOS-KERESKED · E-KERESKEDELMI P · E-KERESKEDELEM  PILLANATNYI K · BIZONYLATOK MEGTEKINT · VISSZA A F · BIZONYLATSZ · Ft · TRB · B-123456 · TRANZAKCI · KIBIZPANEL · PILLANATNYI K · 12 550 000 Ft · VISSZA · ELEKTROMOS KERESKED · BIZONYLAT · FORINT · PTAR

## Eljárások / függvények (.pas)
`AlapAdatBeolvasas`, `BeBizonylatPrint`, `BeKonyveles`, `BeMegsemGombClick`, `BeOkeGombClick`, `BeOsszegEditEnter`, `BeOsszegEditExit`, `BeOsszegEditKeyDown`, `BevetGombClick`, `BizonylatGombClick`, `BizVisszaGombClick`, `FormActivate`, `KeszletGombClick`, `KiadGombClick`, `KiBizonylatPrint`, `KiKonyveles`, `KiMegsemGombClick`, `KiOkeGombClick`, `KiOsszegEditKeyDown`, `KozepreIr`, `MatDataBeolvas`, `MatricaGombClick`, `PillVisszaGombClick`, `PlombaAdatBeolvasas`, `Ptarbeolvasas`, `RePrintGombClick`, `ReturnGombClick`, `TextKiiro`, `ValutaParancs`, `VonalHuzo`

## Érintett adatbázis-táblák
`HARDWARE`, `MATBIZONYLAT`, `MATDATA`, `PENZTAR`, `VTEMP`

**SQL-műveletek (minta):**
- `SELECT * FROM MATDATA`
- `SELECT * FROM VTEMP`
- `INSERT INTO MATBIZONYLAT (DATUM,BIZONYLATSZAM,OSSZEG,TARSPENZTAR,`
- `UPDATE MATDATA SET AKTKESZLET=`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
