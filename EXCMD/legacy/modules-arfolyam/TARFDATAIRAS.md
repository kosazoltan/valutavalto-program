# Legacy modul (ARFOLYAM / árfolyamkészítő): TARFDATAIRAS

> **Funkció:** arfdata.dat írás (árfolyam-fájl perzisztálás)
> Forrás (primer, VALÓDI Object Pascal): `Anti/SZERVER/_extracted/SZERVER/fejleszt/arfolyam/verzio22/arfolyam_unpacked/Unit5.pas` (12624 karakter)
> Alrendszer: **ARFOLYAM** (rate-maker). KORREKCIÓ: a forrás megvan, NEM csak bináris-RE.

## Komponensek (form-mezők)
`INDITO:TTimer`, `Label1:TLabel`, `Memo1:TMemo`, `ARFDATAIRAS:TARFDATAIRAS`, `_olvas:Textfile`

## Eljárások / függvények
`FormActivate`, `INDITOTimer`, `HelyiMentes`, `Stringiras`, `ByteIras`, `WordIras`, `SzinIras`, `ArfDataToServer`, `Safetysave`, `GetSorszam`, `VanInternet`

## Feliratok/gombok (DFM Caption)
_(nincs/bináris DFM)_

## Érintett adatbázis/fájl
_(arfdata.dat fájl-alapú, nincs SQL-tábla)_

## Felhasználói üzenetek
_(nincs)_

## Megfeleltetés a jelenlegi programmal
_(a jelenlegi rate-maker: arfolyam-keszito-client + frontend-react MainRateSheetPage/RateCreationPage + rfmRules ellen verifikálandó.)_
