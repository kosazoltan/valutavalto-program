# Legacy modul (ARFOLYAM / árfolyamkészítő): TGetFuggveny

> **Funkció:** képlet/függvény segéd (cella-másolás)
> Forrás (primer, VALÓDI Object Pascal): `Anti/SZERVER/_extracted/SZERVER/fejleszt/arfolyam/verzio22/arfolyam_unpacked/Unit3.pas` (10725 karakter)
> Alrendszer: **ARFOLYAM** (rate-maker). KORREKCIÓ: a forrás megvan, NEM csak bináris-RE.

## Komponensek (form-mezők)
`Panel1:TPanel`, `FuggvenyShape:TShape`, `ErtekShape:TShape`, `MintaHatter:TShape`, `Label1:TLabel`, `Label2:TLabel`, `MintaBetu:TLabel`, `BetuszinGomb:TBitBtn`, `HatterSzinGomb:TBitBtn`, `MegsemGomb:TBitBtn`, `RendbenGomb:TBitBtn`, `ERTEKEDIT:TEdit`, `ColorDialog1:TColorDialog`, `fuggvenyedit:TEdit`, `GetFuggveny:TGetFuggveny`

## Eljárások / függvények
`FormActivate`, `BetuSzinGombClick`, `HatterSzinGombClick`, `ERTEKEDITEnter`, `ERTEKEDITExit`, `ERTEKEDITKeyDown`, `FuggvenyEditChange`, `FuggvenyEditEnter`, `FuggvenyEditExit`, `FuggvenyEditKeyDown`, `RendbenGombClick`, `MegsemGombClick`, `FuggvenyCtrl`, `Fit`, `JoBetu`, `Besorol`

## Feliratok/gombok (DFM Caption)
BET · RENDBEN

## Érintett adatbázis/fájl
_(arfdata.dat fájl-alapú, nincs SQL-tábla)_

## Felhasználói üzenetek
_(nincs)_

## Megfeleltetés a jelenlegi programmal
_(a jelenlegi rate-maker: arfolyam-keszito-client + frontend-react MainRateSheetPage/RateCreationPage + rfmRules ellen verifikálandó.)_
