# Legacy modul (SZERVER-FEJLESZT): HAVITABLO

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/havitablo/unit1.pas` (25239 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/havitablo/havitablo.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`, `TEXCELKESZITES`

**Feliratok/gombok (Caption):** Form1 · ADJA MEG A K · 2022  SZEPTEMBER · EXCELKESZITES · EXCELT · KIL · AZ EXCELT · C:\HAVITABLO\EXCEL\HAVITAB2201,XLS

## Eljárások / függvények (.pas)
`IrodaBeolvasas`, `FormActivate`, `HONAPMEGSEMGOMBClick`, `EVCOMBOChange`, `HONAPOKEGOMBClick`, `AdatGyujtes`, `IrodaNullazas`, `UresControl`, `NyitoFix`, `Belsofix`, `ExcelKill`, `Logiro`, `WzarBedolgozas`, `BfBedolgozas`, `KezdBedolgozas`, `EfejBedolgozas`, `Nulele`, `Getpenztarnev`, `ScanPenztar`, `ScanErtektar`, `Urctrl`, `TForm1.IrodaNullazas`, `TForm1.FormActivate`, `TForm1.EVCOMBOChange`, `TForm1.HONAPOKEGOMBClick`, `TForm1.adatgyujtes`, `TForm1.WzarBedolgozas`, `TForm1.BFBedolgozas`, `TForm1.KezdBedolgozas`, `TForm1.EfejBedolgozas`

## Érintett adatbázis-táblák
`IRODAK`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `WHERE STORNO=1`
- `SELECT * FROM IRODAK`
- `WHERE CLOSED=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- HIBÁS A KÉRT HÓNAP

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
