# Legacy modul: NAPKONYV

> Forrás (primer): `Anti/VALUTA/DLL/NAPKONYV/MAKEDLL/Unit2.pas` (31901 karakter) · library: `DLL/NAPKONYV/MAKEDLL/napkonyv.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`napikonyvelorutin`

## DFM form(ok) / képernyő
`Tdaybook`

**Feliratok/gombok (Caption):** Napi k · Vissza a f · El · 2013 · szeptember · 25 · cs · bizonylat · Panel2

## Eljárások / függvények (.pas)
`Egyadatsor`, `EgynapiRekordInsert`, `KetpeldanyPrint`, `ElohoGombClick`, `EvhonapDisplay`, `Fejlec`, `FormActivate`, `KilepoTimerTimer`, `KovHoGombClick`, `Kozepre`, `Lablec`, `NaploNapiPrintBejegyzes`, `NyomtatoGombClick`, `Szamtan`, `Ujoldaltnyit`, `ValutaParancs`, `VisszaGombClick`, `EloKieg`, `Form11`, `FtFormalo`, `GetNyito`, `Getvarosnev`, `GetZaro`, `Hundatetostr`, `Nulele`, `NulKieg`, `PtarKepzo`, `NAPTARChange`, `supervisorjelszo`, `Tdaybook.FormActivate`

## Érintett adatbázis-táblák
`DEKADJELENTES`, `HARDWARE`, `PENZTAR`, `PRINTCONTROL`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM DEKADJELENTES ORDER BY KEZDONAP`
- `DELETE FROM DEKADJELENTES`
- `SELECT * FROM PRINTCONTROL`
- `WHERE DATUMDEKAD=`
- `INSERT INTO PRINTCONTROL (KEZDIJPRINT,DEKADPRINT,DATUMDEKAD)`
- `UPDATE PRINTCONTROL SET DEKADPRINT=1`
- `SELECT * FROM`
- `WHERE DATUM<`
- `WHERE VALUTANEM=`
- `WHERE DATUM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
