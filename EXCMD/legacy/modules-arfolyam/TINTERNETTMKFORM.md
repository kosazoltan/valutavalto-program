# Legacy modul (ARFOLYAM / árfolyamkészítő): TINTERNETTMKFORM

> **Funkció:** INTERNET-cím (URL) karbantartó — gomb {sorszám, felirat, URL}
> Forrás (primer, VALÓDI Object Pascal): `Anti/SZERVER/_extracted/SZERVER/fejleszt/arfolyam/verzio22/arfolyam_unpacked/Unit2.pas` (7335 karakter)
> Alrendszer: **ARFOLYAM** (rate-maker). KORREKCIÓ: a forrás megvan, NEM csak bináris-RE.

## Komponensek (form-mezők)
`Panel1:TPanel`, `Shape1:TShape`, `UJINTERNETGOMB:TBitBtn`, `INTERNETDELETEGOMB:TBitBtn`, `VISSZAGOMB:TBitBtn`, `Label1:TLabel`, `Label2:TLabel`, `UJINTERNETPANEL:TPanel`, `Label3:TLabel`, `Label4:TLabel`, `INTERNETCIMEDIT:TEdit`, `Label5:TLabel`, `GOMBFELIRATEDIT:TEdit`, `Label6:TLabel`, `GOMBSZAMEDIT:TEdit`, `UJURLOKEGOMB:TBitBtn`, `UJURLMEGSEMGOMB:TBitBtn`, `URLTORLOPANEL:TPanel`, `INTERNETCIMLISTA:TListBox`, `Label7:TLabel`, `DELCIMPANEL:TPanel`, `Label8:TLabel`, `TORLOGOMB:TBitBtn`, `MEGSEMGOMB:TBitBtn`, `TAKAROPANEL:TPanel`, `INTERNETTMKFORM:TINTERNETTMKFORM`, `Shift:TShiftState`

## Eljárások / függvények
`UJURLMEGSEMGOMBClick`, `FormActivate`, `INTERNETCIMEDITEnter`, `INTERNETCIMEDITExit`, `UJINTERNETGOMBEnter`, `UJINTERNETGOMBExit`, `UJINTERNETGOMBMouseMove`, `VISSZAGOMBClick`, `UJINTERNETGOMBClick`, `INTERNETCIMEDITKeyDown`, `GOMBFELIRATEDITKeyDown`, `GOMBSZAMEDITKeyDown`, `UJURLOKEGOMBClick`, `INTERNETDELETEGOMBClick`, `INTERNETCIMLISTADblClick`, `TORLOGOMBClick`, `MEGSEMGOMBClick`

## Feliratok/gombok (DFM Caption)
INTERNETTMKFORM · MEN · AZ INTERNETC · EGY  · EGY INTERNET C · VISSZA AZ ALAPLAP SZERKESZT · A R · A MEGH · BIZTOSAN T

## Érintett adatbázis/fájl
_(arfdata.dat fájl-alapú, nincs SQL-tábla)_

## Felhasználói üzenetek
_(nincs)_

## Megfeleltetés a jelenlegi programmal
_(a jelenlegi rate-maker: arfolyam-keszito-client + frontend-react MainRateSheetPage/RateCreationPage + rfmRules ellen verifikálandó.)_
