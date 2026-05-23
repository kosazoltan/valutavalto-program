# Legacy modul: LISTAK

> Forrás (primer): `Anti/VALUTA/DLL/LISTAK/MAKEDLL/Unit2.pas` (46378 karakter) · library: `DLL/LISTAK/MAKEDLL/Listak.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`kulonfelelistak`

## DFM form(ok) / képernyő
`TLISTAFORM`

**Feliratok/gombok (Caption):** LISTAFORM · ADAT · KIADOTT BIZONYLATOK LIST · TRB FORGALMI LIST · ELAD · HAVI TABL · HAVI KEDVEZM · PILLANATNYI K · DEK · KEZEL · VALUTA · VISSZA · NYOMTAT · Valuta · Eladva · Forint  · KIADOTT BIZONYLATOK 200811.23  · BIZONYLATSZ · FORINT  · ADAT-LEGY · 2017.01.14 · 2017.01.22 · TEMAFOCIMPANEL

## Eljárások / függvények (.pas)
`AdatDumpList`, `AdvetVisszaGombClick`, `AlapadatBeolvasas`, `BitBtn2Click`, `BizListFejlec`, `BizonylatLista`, `BizonylatListaPrint`, `BizVisszaGombClick`, `BlokkFocimIro`, `DekadLista`, `ForgstatLista`, `FormActivate`, `GetKertdatumAdatok`, `HavitabloDisplay`, `KezdijLista`, `KozepreIr`, `Menube`, `MenugombClick`, `PenztarForgalomLista`, `PtForglist`, `PTForgVisszaGombClick`, `TextKiiro`, `ValParancs`, `VonalHuzo`, `MaiforgOsszesito`, `STATIGOMBClick`, `Elokieg`, `ForintForm`, `FtForm`, `FormKiir`

## Érintett adatbázis-táblák
`BLOKKFEJ`, `BLOKKTETEL`, `EVISTATISZTIKA`, `HARDWARE`, `IDOSZAK`, `PENZTAR`, `PENZTARFORGALOM`, `VTEMP`

**SQL-műveletek (minta):**
- `DELETE FROM VTEMP`
- `SELECT * FROM`
- `WHERE (DATUM>=`
- `INSERT INTO VTEMP (DATUM,TIPUS,VALUTANEM,ARFOLYAM,BANKJEGY,`
- `SELECT * FROM BLOKKTETEL`
- `INSERT INTO VTEMP (DATUM,TIPUS,VALUTANEM,ARFOLYAM,`
- `SELECT * FROM VTEMP`
- `SELECT * FROM VTEMP WHERE TIPUS=`
- `DELETE FROM PENZTARFORGALOM`
- `SELECT FEJ.*,TET.*`
- `FROM`
- `WHERE (FEJ.DATUM>=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NEM VOLT 
- SIKERTELEN KEZELÉSI DIJ LISTA NYOMTATÁS

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
