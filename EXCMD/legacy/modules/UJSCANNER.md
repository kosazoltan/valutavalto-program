# Legacy modul: UJSCANNER

> Forrás (primer): `Anti/VALUTA/DLL/UJSCANNER/MAKEDLL/Unit2.pas` (13306 karakter) · library: `DLL/UJSCANNER/MAKEDLL/scanner.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`ujokmanyszkennelo`

## DFM form(ok) / képernyő
`TForm2`

**Feliratok/gombok (Caption):** OKM · AZ  · FILEN · TWAIN SOURCE DARAB:  · TWAIN SOURCES: · CURRENT SOURCE: · SZKENNEL · Siker · IGEN - SIKERESEN BEOLVASTAM · NEM -  · SOFTWARE L

## Eljárások / függvények (.pas)
`AdatBeolvasas`, `VisszaGombClick`, `FormActivate`, `OldDocsDisplay`, `JobbNyilClick`, `BalNyilClick`, `ScanGombClick`, `SourceManagerBetoltes`, `KepHelyreMasolas`, `IgenGOMBClick`, `MegsemGombClick`, `RetryGombClick`, `DriverComboClick`, `WinExecAndWait32`, `TForm2.FormActivate`, `TForm2.Adatbeolvasas`, `TForm2.OldDocsDisplay`, `TForm2.VisszaGombClick`, `TForm2.JOBBNYILClick`, `TForm2.BALNYILClick`, `TForm2.SCANGOMBClick`, `TForm2.SourceManagerBetoltes`, `TForm2.KepHelyreMasolas`, `TForm2.IGENGOMBClick`, `TForm2.MEGSEMGOMBClick`, `TForm2.RETRYGOMBClick`, `TForm2.DRIVERCOMBOClick`, `TForm2.WinExecAndWait32`

## Érintett adatbázis-táblák
`VTEMP`

**SQL-műveletek (minta):**
- `SELECT * FROM VTEMP`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NINCS ÜGYFÉLSZÁM - NEM LEHET SZKENNELNI

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
