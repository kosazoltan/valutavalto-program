# Legacy modul (ÉRTÉKTÁR): LISTAK

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/listak/debug/unit2.pas` (40653 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/listak/makedll/listak.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`kulonfelelistak`

## DFM form(ok) / képernyő
`TForm1`, `TLISTAFORM`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · LISTAFORM · ADAT · KIADOTT BIZONYLATOK LIST · TRB FORGALMI LIST · HAVI TABL · DEK · KEZEL · VALUTA · VISSZA · NYOMTAT · ELAD · Valuta · Eladva · Forint  · KIADOTT BIZONYLATOK 200811.23  · BIZONYLATSZ · FORINT  · ADAT-LEGY · 2017.01.14 · 2017.01.22 · TEMAFOCIMPANEL

## Eljárások / függvények (.pas)
`AdatDumpList`, `AdvetVisszaGombClick`, `AlapadatBeolvasas`, `BitBtn2Click`, `BizListFejlec`, `BizonylatLista`, `BizonylatListaPrint`, `BizVisszaGombClick`, `BlokkFocimIro`, `DekadLista`, `FormActivate`, `GetKertdatumAdatok`, `HavitabloDisplay`, `KezdijLista`, `KozepreIr`, `Menube`, `MenugombClick`, `PenztarForgalomLista`, `PtForglist`, `PTForgVisszaGombClick`, `TextKiiro`, `ValParancs`, `VonalHuzo`, `MaiforgOsszesito`, `STATIGOMBClick`, `Elokieg`, `ForintForm`, `FtForm`, `FormKiir`, `Nulele`

## Érintett adatbázis-táblák
`BLOKKFEJ`, `BLOKKTETEL`, `HARDWARE`, `IDOSZAK`, `PENZTAR`, `PENZTARFORGALOM`, `VTEMP`

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
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
