# Legacy modul (SZERVER-FEJLESZT mély): KEZDEK

> Forrás (primer): `Anti/VALUTA/DLL/KEZDEKAD/DEBUG/Unit2.pas` (23081 karakter) · library: `Anti/VALUTA/DLL/KEZDEKAD/MAKEDLL/kezdek.dpr`
> Beágyazott sub-modul (a korábbi top-level generálás kihagyta). VALÓDI Delphi-forrás.

## Exportált API
`kezelesidijdekad`

## Eljárások / függvények
`DekadNyomtatas`, `DekadPrintGombClick`, `Dekadszamitas`, `Doskozep`, `EvComboChange`, `FormActivate`, `KilepoTimerTimer`, `LastsorszamRogzito`, `NaploBejegyzes`, `NaploParancs`, `PenztarAdatBeolvaso`, `ValutaParancs`, `VonalHuzas`, `VisszaGombClick`, `Form11`, `Nulele`, `NulKieg`, `PtarKepzo`, `supervisorjelszo`, `TKezdDekad.FormActivate`, `TKezdDekad.DekadPrintGombClick`, `TKezdDekad.Dekadnyomtatas`, `TKezdDekad.DekadSzamitas`, `TKEZDDEKAD.Nulele`, `TKEZDDEKAD.NulKieg`, `TKEZDDEKAD.PtarKepzo`, `TKezdDekad.Form11`, `TKezdDekad.Doskozep`, `TKezdDekad.VonalHuzas`, `TKezdDekad.KilepoTimerTimer`

## DFM Caption-ök
Form1 · Button1 · Button2 · KEZDDEKAD · KEZEL · Dek · Vissza a f · kEZEL · KIL

## Adatbázis-táblák
`BLOKKFEJ`, `HARDWARE`, `KEZDIJSORSZAM`, `NAPIKEZELESIDIJ`, `PENZTAR`, `PRINTCONTROL`

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

## Felhasználói üzenetek
- Csak péntári gépen futtatható
- A KÉRT DEKÁD A JÖVŐBEN LESZ !
- NINCS LEZÁRVA A MAI NAP

## Megfeleltetés a jelenlegi programmal
_(a tényleges jelenlegi kód ellen verifikálandó.)_
