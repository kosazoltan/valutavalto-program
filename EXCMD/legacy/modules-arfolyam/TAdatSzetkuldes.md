# Legacy modul (ARFOLYAM / árfolyamkészítő): TAdatSzetkuldes

> **Funkció:** árfolyamok szétküldése az irodáknak
> Forrás (primer, VALÓDI Object Pascal): `Anti/SZERVER/_extracted/SZERVER/fejleszt/arfolyam/verzio22/arfolyam_unpacked/Unit6.pas` (15663 karakter)
> Alrendszer: **ARFOLYAM** (rate-maker). KORREKCIÓ: a forrás megvan, NEM csak bináris-RE.

## Komponensek (form-mezők)
`Indito:TTimer`, `ErrorPanel:TPanel`, `Panel1:TPanel`, `RendbenPanel:TPanel`, `Label1:TLabel`, `Label2:TLabel`, `ListBox1:TListBox`, `AdatSzetkuldes:TAdatSzetkuldes`

## Eljárások / függvények
`FormActivate`, `INDITOTimer`, `UjDataFileWrite`, `OldDataFileWrite`, `ByteIras`, `WordIras`, `FloatIras`, `KONFIRMGOMBClick`, `ArfolyamKiiro`, `RemoteFileDelete`, `Nulele`, `UploadFiles`, `VanInternet`

## Feliratok/gombok (DFM Caption)
AZ  · A SZERVEREN KERESZT · SIKERES  · CSAK A P

## Érintett adatbázis/fájl
_(arfdata.dat fájl-alapú, nincs SQL-tábla)_

## Felhasználói üzenetek
- Nincs internetkapcsolat ! A feltöltés nem lehetséges
- NINCS INTERNET !

## Megfeleltetés a jelenlegi programmal
_(a jelenlegi rate-maker: arfolyam-keszito-client + frontend-react MainRateSheetPage/RateCreationPage + rfmRules ellen verifikálandó.)_
