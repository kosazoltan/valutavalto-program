# Legacy modul (ARFOLYAM / árfolyamkészítő): TIRODANEVLISTA

> **Funkció:** iroda-név lista (árfolyam-csoport→iroda hozzárendelés)
> Forrás (primer, VALÓDI Object Pascal): `Anti/SZERVER/_extracted/SZERVER/fejleszt/arfolyam/verzio22/arfolyam_unpacked/Unit16.pas` (7046 karakter)
> Alrendszer: **ARFOLYAM** (rate-maker). KORREKCIÓ: a forrás megvan, NEM csak bináris-RE.

## Komponensek (form-mezők)
`VISSZAGOMB:TBitBtn`, `Label1:TLabel`, `IRODAVALASZTOGOMB:TBitBtn`, `ListBox1:TListBox`, `KILEPO:TTimer`, `Shape1:TShape`, `UJPENZTARGOMB:TBitBtn`, `UJPPANEL:TPanel`, `Label2:TLabel`, `SZAMEDIT:TEdit`, `NEVEDIT:TEdit`, `Label3:TLabel`, `Label4:TLabel`, `ujptokegomb:TBitBtn`, `ujmegsemgomb:TBitBtn`, `Shape2:TShape`, `IRODANEVLISTA:TIRODANEVLISTA`

## Eljárások / függvények
`FormActivate`, `Listboxfeltoltes`, `ListBox1DblClick`, `ListBox1KeyDown`, `IRODAVALASZTOGOMBClick`, `IrodatValasztott`, `VISSZAGOMBClick`, `KILEPOTimer`, `UJPENZTARGOMBClick`, `ujmegsemgombClick`, `ujptokegombClick`, `SZAMEDITEnter`, `SZAMEDITExit`, `SZAMEDITKeyDown`, `NEVEDITKeyDown`, `Haromstr`, `VanIlyenIrodaszam`

## Feliratok/gombok (DFM Caption)
IRODANEVLISTA · Csoporton kiv · UJ P · Az  · Neve:

## Érintett adatbázis/fájl
_(arfdata.dat fájl-alapú, nincs SQL-tábla)_

## Felhasználói üzenetek
- ILYEN SZÁMÚ IRODA MÁR VAN !

## Megfeleltetés a jelenlegi programmal
_(a jelenlegi rate-maker: arfolyam-keszito-client + frontend-react MainRateSheetPage/RateCreationPage + rfmRules ellen verifikálandó.)_
