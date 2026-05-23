# Legacy modul (ARFOLYAM / árfolyamkészítő): TAdatBetoltes

> **Funkció:** adat-betöltés (arfdata.dat olvasás)
> Forrás (primer, VALÓDI Object Pascal): `Anti/SZERVER/_extracted/SZERVER/fejleszt/arfolyam/verzio22/arfolyam_unpacked/Unit12.pas` (24100 karakter)
> Alrendszer: **ARFOLYAM** (rate-maker). KORREKCIÓ: a forrás megvan, NEM csak bináris-RE.

## Komponensek (form-mezők)
`Indito:TTimer`, `TimeoutTimer:TTimer`, `ListBox1:TListBox`, `BiztosanGomb:TBitBtn`, `MegsemGomb:TBitBtn`, `BiztosPanel:TPanel`, `Label3:TLabel`, `KERDOPANEL:TPanel`, `Label1:TLabel`, `negomb:TBitBtn`, `igengomb:TBitBtn`, `Label2:TLabel`, `Shape1:TShape`, `KILEPOTIMER:TTimer`, `SIKERESPANEL:TPanel`, `alappanel:TPanel`, `Label4:TLabel`, `AdatBetoltes:TAdatBetoltes`

## Eljárások / függvények
`FormActivate`, `InditoTimer`, `AdatBedolgozo`, `AdatNullazo`, `RENDBENGOMBClick`, `TIMEOUTTIMERTimer`, `NEGOMBClick`, `IGENGOMBClick`, `BIZTOSANGOMBClick`, `MEGSEMGOMBClick`, `KILEPOTIMERTimer`, `AdatLetoltes`, `VanInternet`, `GetByte`, `Getword`, `GetSzin`, `Getstring`, `GetDnemDarab`

## Feliratok/gombok (DFM Caption)
ADATBETOLTES · SIKERES ADATLET · ADATOK LET · A SAJ · NE · IGEN · BIZTOSAN ?? · BIZTOSAN

## Érintett adatbázis/fájl
_(arfdata.dat fájl-alapú, nincs SQL-tábla)_

## Felhasználói üzenetek
- NINCS INTERNET !
- AZ ÁRFOLYAM ADATOK VERZIÓJA ELTÉR A PROGRAMÉTÓL
- SZERVER NEM VÁLASZOL
- NEM TUDTAM LETÖLTENI AZ ARFDATA.DAT ÁRFOLYAM-FILE-T !
- NEM TALÁLOM 

## Megfeleltetés a jelenlegi programmal
_(a jelenlegi rate-maker: arfolyam-keszito-client + frontend-react MainRateSheetPage/RateCreationPage + rfmRules ellen verifikálandó.)_
