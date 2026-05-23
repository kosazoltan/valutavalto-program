# Legacy modul: KEZDEKAD

> Forrás (primer): `Anti/VALUTA/DLL/KEZDEKAD/MAKEDLL/Unit2.pas` (23081 karakter) · library: `DLL/KEZDEKAD/MAKEDLL/kezdek.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`kezelesidijdekad`

## DFM form(ok) / képernyő
`TKEZDDEKAD`

**Feliratok/gombok (Caption):** KEZDDEKAD · KEZEL · Dek · Vissza a f

## Eljárások / függvények (.pas)
`DekadNyomtatas`, `DekadPrintGombClick`, `Dekadszamitas`, `Doskozep`, `EvComboChange`, `FormActivate`, `KilepoTimerTimer`, `LastsorszamRogzito`, `NaploBejegyzes`, `NaploParancs`, `PenztarAdatBeolvaso`, `ValutaParancs`, `VonalHuzas`, `VisszaGombClick`, `Form11`, `Nulele`, `NulKieg`, `PtarKepzo`, `supervisorjelszo`, `TKezdDekad.FormActivate`, `TKezdDekad.DekadPrintGombClick`, `TKezdDekad.Dekadnyomtatas`, `TKezdDekad.DekadSzamitas`, `TKEZDDEKAD.Nulele`, `TKEZDDEKAD.NulKieg`, `TKEZDDEKAD.PtarKepzo`, `TKezdDekad.Form11`, `TKezdDekad.Doskozep`, `TKezdDekad.VonalHuzas`, `TKezdDekad.KilepoTimerTimer`

## Érintett adatbázis-táblák
`BLOKKFEJ`, `HARDWARE`, `KEZDIJSORSZAM`, `NAPIKEZELESIDIJ`, `PENZTAR`, `PRINTCONTROL`

**SQL-műveletek (minta):**
- `SELECT * FROM BLOKKFEJ`
- `SELECT * FROM`
- `WHERE (DATUM>=`
- `SELECT * FROM NAPIKEZELESIDIJ`
- `WHERE DATUM<`
- `SELECT * FROM KEZDIJSORSZAM WHERE (EV=`
- `DELETE FROM KEZDIJSORSZAM`
- `WHERE (EV=`
- `INSERT INTO KEZDIJSORSZAM (EV,HONAP,DEKAD,UTOLSOSORSZAM)`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PRINTCONTROL`

## Felhasználói üzenetek (üzleti szabály-jelek)
- Csak péntári gépen futtatható
- A KÉRT DEKÁD A JÖVŐBEN LESZ !
- NINCS LEZÁRVA A MAI NAP

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
