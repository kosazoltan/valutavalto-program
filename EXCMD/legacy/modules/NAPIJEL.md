# Legacy modul: NAPIJEL

> Forrás (primer): `Anti/VALUTA/DLL/NAPIJEL/MAKEDLL/Unit2.pas` (42484 karakter) · library: `DLL/NAPIJEL/MAKEDLL/NAPIJEL.DPR`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`napijelrutin`

## DFM form(ok) / képernyő
`TNAPIJELENTES`

**Feliratok/gombok (Caption):** KEZEL · 257 426 000 Ft · E-KERESKEDELEM · 345 000 000 Ft · Jelent · Most nem k · Pillanatnyi p · DNEM · ELAD · 20 000 · 4 500 · 10 000 · 100 · 112 · 1 200 · 50 · 5 000 · 2 000 · 1 000 · 500 · 200 · 20 · 10 · 166 · 4 100

## Eljárások / függvények (.pas)
`AdatlapKijelzes`, `AdatlapTorles`, `AlapAdatBeolvasas`, `BekuldoGombClick`, `ByteKoder`, `CancelGombClick`, `FormActivate`, `InditoTimerTimer`, `IntegerKoder`, `JelentesIras`, `MemoAnalizis`, `MemoKerekEnter`, `MemoKerekExit`, `PillParancs`, `Textkoder`, `TombBerakas`, `ValutaParancs`, `WordKoder`, `Arfform`, `CimletBeolvasas`, `ForgalomBeolvasas`, `Ftform`, `GetJelentesPath`, `KedvezmenyBeolvasas`, `ScanDnem`, `KILEPOTimer`, `TNAPIJELENTES.FormActivate`, `TNAPIJELENTES.INDITOTIMERTimer`, `TNapiJelentes.CimletBeolvasas`, `TNapiJelentes.KedvezmenyBeolvasas`

## Érintett adatbázis-táblák
`ARFOLYAM`, `BF`, `BT`, `HARDWARE`, `NAPIKEZELESIDIJ`, `NAPIZAR`, `PARAMETERS`, `PENZTAR`, `WZAR`

**SQL-műveletek (minta):**
- `SELECT * FROM WZAR`
- `WHERE DATUM=`
- `SELECT * FROM NAPIKEZELESIDIJ`
- `SELECT * FROM PARAMETERS`
- `SELECT * FROM`
- `SELECT * FROM BF`
- `WHERE (DATUM=`
- `SELECT * FROM BT`
- `WHERE BIZONYLATSZAM=`
- `DELETE FROM NAPIZAR`
- `INSERT INTO NAPIZAR (VALUTANEM,VETEL,ELADAS,ZARO)`
- `SELECT * FROM NAPIZAR`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NEM TALÁLOM A 
- A NAPI JELENTÉS KÜLDÉSRE ELÖKÉSZITVE !

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
