# Legacy modul: CIMLCTRL

> Forrás (primer): `Anti/VALUTA/DLL/CIMLCTRL/MAKEDLL/Unit2.pas` (11572 karakter) · library: `DLL/CIMLCTRL/MAKEDLL/CimlCtrl.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`cimletctrlrutin`

## DFM form(ok) / képernyő
`TCIMLETCONTROL`

**Feliratok/gombok (Caption):** CIMLETCONTROL · CIMLETEK ELLEN

## Eljárások / függvények (.pas)
`FormActivate`, `InditoTimer`, `GetPenztarZarasAdatai`, `Getkezelesidij`, `GetWestern`, `GetafaKeszlet`, `GetfoglaloKeszlet`, `GetEtradeKeszlet`, `Cparancs`, `TCIMLETCONTROL.FormActivate`, `TCIMLETCONTROL.INDITOTimer`, `TcimletControl.GetPenztarZarasAdatai`, `Tcimletcontrol.Getkezelesidij`, `TcimletControl.GetWestern`, `TcimletControl.GetAfaKeszlet`, `Tcimletcontrol.GetfoglaloKeszlet`, `TCimletControl.GetEtradekeszlet`, `TCimletcontrol.Cparancs`

## Érintett adatbázis-táblák
`ARFOLYAM`, `CIMINI`, `FOGLALOKESZLET`, `HARDWARE`, `KEZELESIDATA`, `PARAMETERS`, `WUAFAADATOK`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `UPDATE CIMINI SET AKTKESZLET=0 WHERE CIMLETTYPE=`
- `SELECT * FROM ARFOLYAM`
- `UPDATE CIMINI SET AKTKESZLET=`
- `WHERE (CIMLETTYPE=1) AND (VALUTANEM=`
- `SELECT * FROM KEZELESIDATA`
- `WHERE CIMLETTYPE=2`
- `SELECT * FROM WUAFAADATOK`
- `WHERE (CIMLETTYPE=3) AND (VALUTANEM=`
- `WHERE (CIMLETTYPE=4)`
- `SELECT * FROM FOGLALOKESZLET`
- `SELECT * FROM CIMINI WHERE (VALUTANEM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
