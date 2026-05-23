# Legacy modul: KEZDIJ

> Forrás (primer): `Anti/VALUTA/DLL/KEZDIJ/MAKEDLL/Unit2.pas` (30404 karakter) · library: `DLL/KEZDIJ/MAKEDLL/KEZDIJ.DPR`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`kezdijatadorutin`

## DFM form(ok) / képernyő
`TKDADVET`

**Feliratok/gombok (Caption):** KDADVET · KEZEL · A KEZEL · BIZONYLATOK MEGTEKINT · VISSZA · Bizonylat sz · B-000666 · A123 · Bizonylat · El · Kezel · Mozg · Mai napi bizonylatok · Bizonylat storn · Vissza a men · Mai napi kezel · STORNO · Nyomtat

## Eljárások / függvények (.pas)
`FormActivate`, `ForintForm`, `KozepreIr`, `TextKiiro`, `VonalHuzo`, `GetKezBizSzamok`, `KozosKezdijRutin`, `PlombaAdatBeolvasas`, `Nulele`, `NapiKezdijDisplay`, `Ptarbeolvasas`, `AlapAdatBeolvasas`, `KezdijNyomtatas`, `ValutaParancs`, `BizonylatChange`, `KEZBIZRACSCellClick`, `KEZBIZRACSKeyUp`, `KEZBIZRACSMouseUp`, `KEZBIZRACSDblClick`, `KezdParancs`, `KEZDATVETGOMBClick`, `KEZDIJEDITEnter`, `KEZDIJEDITExit`, `KEZDIJEDITKeyDown`, `KEZKONYVELOGOMBClick`, `KEZKONYVMEGSEMGOMBClick`, `KEZDATADGOMBClick`, `KEZDBIZONYLATGOMBClick`, `KEZDPILLGOMBClick`, `KEZDVISSZAGOMBClick`

## Érintett adatbázis-táblák
`HARDWARE`, `KEZELESIDATA`, `KEZELESIDIJ`, `PENZTAR`, `VTEMP`

**SQL-műveletek (minta):**
- `INSERT INTO KEZELESIDIJ (DATUM,BIZONYLAT,ELOJEL,KEZELESIDIJ,`
- `UPDATE KEZELESIDATA SET UTBEVET=`
- `UPDATE KEZELESIDATA SET UTKIADAS=`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM KEZELESIDATA`
- `SELECT * FROM VTEMP`
- `INSERT INTO KEZELESIDIJ (DATUM,BIZONYLAT,MOZGAS,KEZELESIDIJ,`
- `UPDATE KEZELESIDATA SET AKTKEZELESIDIJ=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- Ennyi kezelési díj nincs !

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
