# Legacy modul (SZERVER-FEJLESZT): EXPADVET

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/expadvet/unit1.pas` (23858 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/expadvet/xadvet.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · EXPRESSZ  · GY · KIL · AZ EXCELT · HELYEN

## Eljárások / függvények (.pas)
`AdvetBeolvasas`, `AdatFeltoltes`, `AdvetParancs`, `BlokkTetelBeolvasas`, `ExcelKill`, `Fejlec`, `FormActivate`, `HoComboChange`, `IrodakBeolvasasa`, `KilepGombClick`, `KilepoTimer`, `Maketabla`, `MakeExcel`, `PenztarStart`, `StartGombClick`, `Vekonykeret`, `Vastagkeret`, `WuniBeolvasas`, `Getpenztarnev`, `Nulele`, `TForm1.FormActivate`, `TForm1.KILEPGOMBClick`, `TForm1.STARTGOMBClick`, `TForm1.AdvetBeolvasas`, `TForm1.BlokktetelBeolvasas`, `TForm1.Maketabla`, `TForm1.WuniBeolvasas`, `TForm1.AdvetParancs`, `tform1.Nulele`, `TForm1.HOCOMBOChange`

## Érintett adatbázis-táblák
`IRODAK`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `WHERE ((TIPUS=`
- `INSERT INTO`
- `WHERE (BIZONYLATSZAM=`
- `DELETE FROM`
- `WHERE ((SORSZAM LIKE`
- `SELECT * FROM IRODAK`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
