# Legacy modul: METRO

> Forrás (primer): `Anti/VALUTA/DLL/METRO/MAKEDLL/Unit2.pas` (71965 karakter) · library: `DLL/METRO/MAKEDLL/Metro.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`metrorutin`

## DFM form(ok) / képernyő
`TMETROFORM`

**Feliratok/gombok (Caption):** METROFORM · Cash and Carry Hungary · METRO · Escape · KIL · EGY · UNIOS  · SZ · BRUTT · AFA  · Ft · Ft. · 123.586 Ft · Bizonylatsz · KIFIZETEND · RENDBEN · UGYKEZDIJPANEL · AV-123456 · UNI · NYOMJA MEG AZ ENTERT · PARTNER: · BIZONYLATSZ · ABDFGHTRFJGTHZUEWDFT · 123.456.789 · TRANZAKCI

## Eljárások / függvények (.pas)
`AfaTranzNyomtatas`, `AfaTranzRegisztralas`, `BizTalloGombClick`, `BizTalloGombEnter`, `BizTalloGombExit`, `BizDispVisszaGombClick`, `ElozoGombClick`, `EscapeGombClick`, `WuKeszletAllito`, `Bizregiszter`, `FejVonalHuzo`, `GetWuKeszlet`, `kerekito`, `Fomenu`, `FomenuKilepoGombClick`, `ForintEditClick`, `ForintEditEnter`, `ForintEditExit`, `FormActivate`, `GetaktwCeg`, `VonalHuzo`, `PlombaAdatBeolvasas`, `GetWcegNev`, `HideEdit2KeyPress`, `IIAtadGombClick`, `IIAtadGombEnter`, `IIAtadGombExit`, `KozepreIr`, `Nulele`, `IIAtadGombMouseMove`

## Érintett adatbázis-táblák
`HARDWARE`, `IDOSZAK`, `METROAFAMOZGAS`, `PENZTAR`, `VTEMP`, `WPENZSZALLITAS`, `WUAFAADATOK`, `WUAFACEGEK`, `WUGYFEL`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `INSERT INTO METROAFAMOZGAS (FOEGYSEGSZAM,UGYFELSZAM,UNIOSAFA,DATUM,IDO,SORSZAM,`
- `SELECT * FROM WUAFACEGEK`
- `WHERE CEGSZAM=`
- `INSERT INTO WPENZSZALLITAS (DATUM,BIZONYLATSZAM,PLOMBASZAM,`
- `INSERT INTO METROAFAMOZGAS (FOEGYSEGSZAM,PENZTARSZAM,ELLATMANYFORINT,`
- `SELECT * FROM WUAFAADATOK`
- `SELECT * FROM`
- `WHERE DATUM BETWEEN`
- `SELECT * FROM METROAFAMOZGAS`
- `UPDATE`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NINCSENEK ADATAIM A KÉRT IDŐSZAKRÓL
- ÜRES A MAI AFA VISSZAIGÉNYLÉS KARTONJA
- NINCS ENNYI 

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
