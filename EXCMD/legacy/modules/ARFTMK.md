# Legacy modul (VALUTA): ARFTMK

> Forrás (primer): `Anti/SZERVER/_extracted/VALUTA/DLL/ARFTMK/DEBUG/Unit2.pas` (28607 karakter)
> KORREKCIÓ: a Anti/VALUTA/DLL-ben 0-bájtos stub volt; a VALÓDI forrás az _extracted/VALUTA/DLL-ben.

## Exportált API
`arfolyamtmkrutin`

## Eljárások / függvények
`AlapadatBeolvasas`, `ARFOLYAMRACSKeyDown`, `ARFNYOMGOMBClick`, `ARFNYOMGOMBEnter`, `ARFNYOMGOMBExit`, `ARFOLYAMRACSDblClick`, `ArftmkNyomtatas`, `DNevEDITEnter`, `DNevEditExit`, `EgyvalutaTmk`, `ElszarfModositas`, `ELSZARFNYOMGOMBClick`, `EscapeGOMBClick`, `FormCreate`, `LetoltoGombClick`, `NyomtatoGombClick`, `NyomtatoPanelClick`, `SICCGOMBClick`, `BlokkFocimiro`, `TextKiiro`, `KozepreIr`, `Forintform`, `ValutaParancs`, `Elokieg`, `Kieg`, `Validalo`, `MertekCtrl`, `DuplaSupkod`, `Arfkiir`, `VARFEDITKeyDown`, `EARFEDITKeyDown`, `ELSZARFEDITKeyDown`, `arfolyamokegombClick`, `ELSZARFGOMBClick`, `ELSZARFEDITExit`, `ELSZARFEDITChange`, `MNBLETOLTOGOMBClick`, `KEZIALLITOGOMBClick`, `arfolyamletoltes`, `supervisorjelszo`

## Érintett adatbázis-táblák
`ARFOLYAM`, `HARDWARE`, `PENZTAR`

- `SELECT * FROM ARFOLYAM ORDER BY VALUTANEM`
- `UPDATE ARFOLYAM SET VETELIARFOLYAM=`
- `WHERE VALUTANEM=`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `UPDATE HARDWARE SET KEZIARFOLYAM=1`

## Felhasználói üzenetek
- A FORINT ÁRFOLYAMA NEM VÁLTOZTATHATÓ
- AZ ELSZÁMOLÓ ÁRFOLYAMOKAT LE KELL TÖLTENI A SZERVERRŐL
- AZ ÚJ VÉTELI ÁRFOLYAM KISEBB AZ ENGEDÉLYEZETTNÉL
- AZ ÚJ ELADÁSI ÁRFOLYAM NAGYOBB AZ ENGEDÉLYEZETTNÉL

## Megfeleltetés a jelenlegi programmal
_(a tényleges jelenlegi kód ellen verifikálandó.)_
