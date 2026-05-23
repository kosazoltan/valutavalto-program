# Legacy modul: GETWUGYF

> Forrás (primer): `Anti/VALUTA/DLL/GETWUGYF/MAKEDLL/Unit2.pas` (17838 karakter) · library: `DLL/GETWUGYF/MAKEDLL/Getwugyf.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`getwesternugyfel`

## DFM form(ok) / képernyő
`TGETWUGYF`

**Feliratok/gombok (Caption):** KERESETT N · Western Union/ · Anyja neve · Okm · Azonos · Lakc · KARTON · Az  · AZ  · ANYJA NEVE: · SZ · LAKC · OKM · WESTERN · UNION · METRO · TESCO · RENDBEN

## Eljárások / függvények (.pas)
`FormActivate`, `ibValutaParancs`, `KartonDisplay`, `GetWuData`, `KARTONGOMBClick`, `GetNextWudata`, `WNEVEDITEnter`, `WNEVEDITExit`, `WNEVEDITKeyDown`, `ujugyfelgombClick`, `WUGYFELRACSKeyPress`, `BackspaceRutin`, `KERESEDITEnter`, `WNEVEDITChange`, `Adatfeliras`, `AdatKiolvasas`, `Ugyfeletvalasztott`, `RENDBENGOMBClick`, `MEGSEMGOMBClick`, `RENDBENGOMBEnter`, `RENDBENGOMBExit`, `RENDBENGOMBMouseMove`, `WUGYFELRACSDblClick`, `FormKeyDown`, `KILEPTimer`, `getwesternugyfel`, `TGETWUGYF.FormActivate`, `TGetWUGYF.BackspaceRutin`, `TGETWUGYF.WUGYFELRACSKeyPress`, `TGETWUGYF.KARTONGOMBClick`

## Érintett adatbázis-táblák
`WUAFAADATOK`, `WUGYFEL`

**SQL-műveletek (minta):**
- `INSERT INTO WUGYFEL (UGYFELSZAM,NEV,ANYJANEVE,SZULETESIHELY,`
- `UPDATE WUGYFEL SET NEV=`
- `WHERE UGYFELSZAM=`
- `SELECT * FROM WUGYFEL`
- `SELECT * FROM WUAFAADATOK`
- `UPDATE WUAFAADATOK SET`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
