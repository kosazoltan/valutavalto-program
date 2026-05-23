# Legacy modul (ÉRTÉKTÁR): CIMLCTRL

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/cimlctrl/debug/unit2.pas` (9126 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/cimlctrl/makedll/cimlctrl.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`cimletctrlrutin`

## DFM form(ok) / képernyő
`TForm1`, `TCIMLETCONTROL`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · CIMLETCONTROL · CIMLETEK ELLEN

## Eljárások / függvények (.pas)
`FormActivate`, `InditoTimer`, `GetPenztarKeszlet`, `GetkezdijKeszlet`, `GetWuKeszlet`, `GetAfakeszlet`, `GetEkerKeszlet`, `Cparancs`, `TCIMLETCONTROL.FormActivate`, `TCIMLETCONTROL.INDITOTimer`, `TcimletControl.GetPenztarKeszlet`, `Tcimletcontrol.GetkezdijKeszlet`, `TcimletControl.GetWUKeszlet`, `TcimletControl.GetAfaKeszlet`, `TCimletControl.GetEkerkeszlet`, `TCimletcontrol.Cparancs`

## Érintett adatbázis-táblák
`ARFOLYAM`, `CIMINI`, `EKERDATA`, `HARDWARE`, `KEZDIJDATA`, `WUAFAADATOK`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `UPDATE CIMINI SET AKTKESZLET=0 WHERE CIMLETTYPE=`
- `SELECT * FROM ARFOLYAM`
- `UPDATE CIMINI SET AKTKESZLET=`
- `WHERE (CIMLETTYPE=1) AND (VALUTANEM=`
- `SELECT * FROM KEZDIJDATA`
- `WHERE CIMLETTYPE=2`
- `SELECT * FROM WUAFAADATOK`
- `WHERE (CIMLETTYPE=3) AND (VALUTANEM=`
- `WHERE (CIMLETTYPE=4)`
- `SELECT * FROM EKERDATA`
- `WHERE (CIMLETTYPE=5)`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
