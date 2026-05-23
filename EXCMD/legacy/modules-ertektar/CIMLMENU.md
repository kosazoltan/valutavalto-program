# Legacy modul (ÉRTÉKTÁR): CIMLMENU

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/cimlmenu/debug/unit2.pas` (4468 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/cimlmenu/makedll/cimlmenu.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`cimletmenurutin`

## DFM form(ok) / képernyő
`TForm1`, `TCIMLETMENU`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · CIMLETMENU · VISSZA · ESTI Z · KEZEL · WESTERN UNION C · ELEKTROMOS KERESKED · KIL

## Eljárások / függvények (.pas)
`Cimletparancs`, `FormActivate`, `HardwareBeolvasas`, `KilepGombClick`, `PtZarGombClick`, `QuitGombClick`, `TCimletMenu.FormActivate`, `TCimletMenu.HardwareBeolvasas`, `TCimletMenu.PtZarGombClick`, `TCimletMenu.Cimletparancs`, `TCimletMenu.KILEPGOMBClick`, `TCimletMenu.QUITGOMBClick`

## Érintett adatbázis-táblák
`HARDWARE`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `UPDATE HARDWARE SET MENETSZAM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
