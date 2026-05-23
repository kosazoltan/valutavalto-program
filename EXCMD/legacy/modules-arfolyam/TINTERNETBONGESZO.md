# Legacy modul (ARFOLYAM / árfolyamkészítő): TINTERNETBONGESZO

> **Funkció:** internet-böngésző (a karbantartott URL-ek megnyitása)
> Forrás (primer, VALÓDI Object Pascal): `Anti/SZERVER/_extracted/SZERVER/fejleszt/arfolyam/verzio22/arfolyam_unpacked/Unit11.pas` (1627 karakter)
> Alrendszer: **ARFOLYAM** (rate-maker). KORREKCIÓ: a forrás megvan, NEM csak bináris-RE.

## Komponensek (form-mezők)
`WebBrowser1:TWebBrowser`, `Label1:TLabel`, `BROWSERBACKGOMB:TBitBtn`, `WEBCLOSEGOMB:TBitBtn`, `INTERNETBONGESZO:TINTERNETBONGESZO`

## Eljárások / függvények
`FormActivate`, `WEBCLOSEGOMBClick`, `BROWSERBACKGOMBClick`

## Feliratok/gombok (DFM Caption)
INTERNETBONGESZO · A kiv · VISSZA A MUNK · WEBLAP BEZ

## Érintett adatbázis/fájl
_(arfdata.dat fájl-alapú, nincs SQL-tábla)_

## Felhasználói üzenetek
_(nincs)_

## Megfeleltetés a jelenlegi programmal
_(a jelenlegi rate-maker: arfolyam-keszito-client + frontend-react MainRateSheetPage/RateCreationPage + rfmRules ellen verifikálandó.)_
