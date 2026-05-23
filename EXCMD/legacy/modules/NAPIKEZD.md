# Legacy modul: NAPIKEZD

> Forrás (primer): `Anti/VALUTA/DLL/NAPIKEZD/MAKEDLL/Unit2.pas` (28745 karakter) · library: `DLL/NAPIKEZD/MAKEDLL/napikezd.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`napikezdijrutin`

## DFM form(ok) / képernyő
`TNAPIKEZD`

**Feliratok/gombok (Caption):** NYOMTAT · VISSZA A F · << EL · Dek

## Eljárások / függvények (.pas)
`Egyadatsor`, `ElohoGombClick`, `EvhonapDisplay`, `Fejlec`, `FormActivate`, `Gethavinyito`, `KilepoTimerTimer`, `Kozepre`, `KovHoGombClick`, `Lablec`, `NaploNapiPrintBejegyzes`, `KezdijNyomtatas`, `NyomtatoGombClick`, `Ujoldaltnyit`, `VisszaGombClick`, `EloKieg`, `EtarScan`, `Form11`, `FtFormalo`, `HunDateTostr`, `KovetkezoNap`, `Nulele`, `NulKieg`, `PtarKepzo`, `NAPTARChange`, `supervisorjelszo`, `TNAPIKEZD.FormActivate`, `TNAPIKEZD.EvhonapDisplay`, `TNAPIKEZD.NyomtatoGombClick`, `Tnapikezd.Gethavinyito`

## Érintett adatbázis-táblák
`HARDWARE`, `PENZTAR`, `PRINTCONTROL`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM`
- `WHERE DATUM<`
- `WHERE DATUM=`
- `WHERE VALUTANEM=`
- `SELECT * FROM PRINTCONTROL`
- `WHERE DATUMDEKAD=`
- `INSERT INTO PRINTCONTROL (KEZDIJPRINT,DEKADPRINT,DATUMDEKAD)`
- `UPDATE PRINTCONTROL SET KEZDIJPRINT=1`

## Felhasználói üzenetek (üzleti szabály-jelek)
- Érvénytelen nap kérése
- Kérem elöbb lezárni a mai napot !
- Nincs a megjelölt napról semmi adat
- NINCSEN KÉSZLET A VÁLASZTOTT NAPON !
- HIBÁS ÉRTÉKTÁRSZÁM !

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
