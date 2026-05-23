# Legacy modul: GEPSETUP

> Forrás (primer): `Anti/VALUTA/DLL/GEPSETUP/MAKEDLL/Unit2.pas` (54913 karakter) · library: `DLL/GEPSETUP/MAKEDLL/GEPSETUP.DPR`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`parameterezes`

## DFM form(ok) / képernyő
`TSETUPFORM`

**Feliratok/gombok (Caption):** SETUPFORM · BE · ALAPFUNKCI · ALKALMAZ · IP-CIM BE · JELSZ · KIJELZ · FUT · KEZEL · BANKK · NYOMTAT · REKL · KIL · VISSZA A MEN · SCANNER BE · LPT1 PORTRA CSATLAKOZTATVA · USB PORTRA CSATLAKOZTATVA · NINCS REKL · VAN REKL · MEGMUTAT · LET · VISSZA · VALUTAV · WESTERN UNION · TESCO 

## Eljárások / függvények (.pas)
`FormActivate`, `MPColorClear`, `MP1MouseMove`, `Tabladisplay`, `PFUNCClick`, `EFUNCClick`, `AFUNCClick`, `VVBOXClick`, `WUBOXClick`, `TAFABOXClick`, `MAFABOXClick`, `EKERBOXClick`, `bestClick`, `eastClick`, `pannonClick`, `pwmodygombClick`, `savegombClick`, `ReklamFeldolgozas`, `FutoFenyBekapcsolasa`, `quitgombClick`, `JELSZOEDITEnter`, `JELSZOEDITExit`, `JELSZOEDITKeyDown`, `EMAILEDITEnter`, `EMAILEDITExit`, `EMAILEDITKeyDown`, `SATOPENClick`, `SATCLOSEDClick`, `ZOLDClick`, `SARGAClick`

## Érintett adatbázis-táblák
`HARDWARE`, `MEDIA`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM MEDIA`
- `UPDATE HARDWARE SET GEPFUNKCIO=`
- `DELETE FROM MEDIA`
- `INSERT INTO MEDIA (FENYTEXT)`
- `UPDATE HARDWARE SET HOST=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
