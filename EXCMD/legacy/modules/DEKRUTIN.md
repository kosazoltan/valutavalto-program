# Legacy modul: DEKRUTIN

> Forrás (primer): `Anti/VALUTA/DLL/DEKRUTIN/MAKEDLL/Unit2.pas` (32638 karakter) · library: `DLL/DEKRUTIN/MAKEDLL/dekad.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`forgalomdekad`

## DFM form(ok) / képernyő
`TDEKADRUTIN`

**Feliratok/gombok (Caption):** DEKADRUTIN · DEK · NYOMTAT

## Eljárások / függvények (.pas)
`BfKiolvasas`, `DekadNyomtatas`, `DekadOkeGombClick`, `DekadParancs`, `DosKozep`, `EvComboChange`, `ForgalomBeolvasas`, `FormActivate`, `MegsemGombClick`, `PenztarAdatBeolvaso`, `RekordFeliras`, `StartDekadszamitas`, `VonalHuzas`, `Form11`, `FtFormalo`, `GetControlZaro`, `GetKezdoNap`, `GetKezdoSorszam`, `GetNapiCImlet`, `GetnyitoForint`, `GetVegsoNap`, `NulEle`, `NulKieg`, `PtarKepzo`, `supervisorjelszo`, `TDEKADRUTIN.FormActivate`, `TDEKADRUTIN.DEKADOKEGOMBClick`, `TDekadrutin.StartDekadSzamitas`, `TDekadRutin.GetControlZaro`, `TDekadRutin.GetnyitoForint`

## Érintett adatbázis-táblák
`BLOKKFEJ`, `DEKADJELENTES`, `HARDWARE`, `PENZTAR`, `PRINTCONTROL`

**SQL-műveletek (minta):**
- `SELECT * FROM BLOKKFEJ`
- `SELECT * FROM`
- `WHERE (DATUM<=`
- `WHERE (DATUM<`
- `WHERE VALUTANEM=`
- `SELECT * FROM PRINTCONTROL WHERE DATUMDEKAD=`
- `INSERT INTO PRINTCONTROL (DEKADPRINT,KEZDIJPRINT,DATUMDEKAD)`
- `UPDATE PRINTCONTROL SET DEKADPRINT=1`
- `WHERE DATUMDEKAD=`
- `DELETE FROM DEKADJELENTES`
- `WHERE KEZDONAP=`
- `INSERT INTO DEKADJELENTES (DEKAD,KEZDONAP,UTOLSONAP,KEZDOSORSZAM,`

## Felhasználói üzenetek (üzleti szabály-jelek)
- A KÉRT DÁTUM A JÖVŐBEN LESZ !

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
