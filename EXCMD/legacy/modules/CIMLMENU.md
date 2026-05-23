# Legacy modul: CIMLMENU

> Forrás (primer): `Anti/VALUTA/DLL/CIMLMENU/MAKEDLL/Unit2.pas` (6101 karakter) · library: `DLL/CIMLMENU/MAKEDLL/CIMLMENU.DPR`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`cimletmenurutin`

## DFM form(ok) / képernyő
`TCIMLETMENU`

**Feliratok/gombok (Caption):** CIMLETMENU · VISSZA · ESTI Z · KEZEL · WESTERN UNION C · FOGLAL · ELEKTROMOS KERESKED · KIL

## Eljárások / függvények (.pas)
`Cimletparancs`, `FormActivate`, `HardwareBeolvasas`, `KilepGombClick`, `PtZarGombClick`, `QuitGombClick`, `TCimletMenu.FormActivate`, `TCimletMenu.HardwareBeolvasas`, `TCimletMenu.PtZarGombClick`, `TCimletMenu.Cimletparancs`, `TCimletMenu.KILEPGOMBClick`, `TCimletMenu.QUITGOMBClick`

## Érintett adatbázis-táblák
`FOGLALOKESZLET`, `HARDWARE`

**SQL-műveletek (minta):**
- `SELECT * FROM FOGLALOKESZLET`
- `SELECT * FROM HARDWARE`
- `UPDATE HARDWARE SET MENETSZAM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
