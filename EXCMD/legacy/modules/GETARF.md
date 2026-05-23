# Legacy modul: GETARF

> Forrás (primer): `Anti/VALUTA/DLL/GETARF/MAKEDLL/Unit2.pas` (32433 karakter) · library: `DLL/GETARF/MAKEDLL/Getarf.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`arfolyamletoltes`

## DFM form(ok) / képernyő
`TGETARFOLYAM`

**Feliratok/gombok (Caption):** GETARFOLYAM · Nem volt · RENDBEN · Rendben · 03

## Eljárások / függvények (.pas)
`FormActivate`, `GetGepParameters`, `InditoTimerTimer`, `Aktarfolyambetoltes`, `DataToKijelzo`, `CrsTorlese`, `FTPszerverbeBelep`, `Changedisplay`, `Nochangedisplay`, `ArfolyamAdatrogzites`, `ibParancs`, `Listbeiras`, `MNBFrissites`, `DnemDekod`, `Scandnem`, `IntegDek`, `dnemDekoder`, `Intdekodol`, `RealToStr`, `Kitkod`, `Formaz`, `HunDatetostr`, `Nulele`, `NochangeGombClick`, `CHANGEGOMBClick`, `KILEPOTimer`, `arfolyamletoltes`, `arfolyamregiszter`, `TGETARFOLYAM.FormActivate`, `TGetarfolyam.GetGepParameters`

## Érintett adatbázis-táblák
`ARFOLYAM`, `HARDWARE`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM ARFOLYAM`
- `UPDATE ARFOLYAM SET ELSZAMOLASIARFOLYAM=`
- `WHERE VALUTANEM=`
- `UPDATE HARDWARE SET LIMIT1=`
- `UPDATE HARDWARE SET KEZIARFOLYAM=0`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NINCS A SZERVEREN MAI NAPI MNB ÁRFOLYAM RÖGZITVE
- NINCSENEK ÁRFOLYAMOK AZ ADATOKBAN
- A központi szerver nem érhető el !
- Hibás csoportkód az árfolyamtáblában !
- Hibás a letöltött árfolyam táblázat !

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
