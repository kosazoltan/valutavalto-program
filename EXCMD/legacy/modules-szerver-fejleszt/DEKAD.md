# Legacy modul (SZERVER-FEJLESZT mély): DEKAD

> Forrás (primer): `Anti/VALUTA/DLL/DEKRUTIN/DEBUG/Unit2.pas` (32638 karakter) · library: `Anti/VALUTA/DLL/DEKRUTIN/MAKEDLL/dekad.dpr`
> Beágyazott sub-modul (a korábbi top-level generálás kihagyta). VALÓDI Delphi-forrás.

## Exportált API
`forgalomdekad`

## Eljárások / függvények
`BfKiolvasas`, `DekadNyomtatas`, `DekadOkeGombClick`, `DekadParancs`, `DosKozep`, `EvComboChange`, `ForgalomBeolvasas`, `FormActivate`, `MegsemGombClick`, `PenztarAdatBeolvaso`, `RekordFeliras`, `StartDekadszamitas`, `VonalHuzas`, `Form11`, `FtFormalo`, `GetControlZaro`, `GetKezdoNap`, `GetKezdoSorszam`, `GetNapiCImlet`, `GetnyitoForint`, `GetVegsoNap`, `NulEle`, `NulKieg`, `PtarKepzo`, `supervisorjelszo`, `TDEKADRUTIN.FormActivate`, `TDEKADRUTIN.DEKADOKEGOMBClick`, `TDekadrutin.StartDekadSzamitas`, `TDekadRutin.GetControlZaro`, `TDekadRutin.GetnyitoForint`

## DFM Caption-ök
Form1 · BitBtn1 · BitBtn2 · DEKADRUTIN · DEK · NYOMTAT · A P · KIL

## Adatbázis-táblák
`BLOKKFEJ`, `DEKADJELENTES`, `HARDWARE`, `PENZTAR`, `PRINTCONTROL`

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

## Felhasználói üzenetek
- A KÉRT DÁTUM A JÖVŐBEN LESZ !

## Megfeleltetés a jelenlegi programmal
_(a tényleges jelenlegi kód ellen verifikálandó.)_
