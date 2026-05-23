# Legacy modul (SZERVER-FEJLESZT): SUMMA

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/summa/unit1.pas` (26633 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/summa/summa.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`, `TMAKEEXCEL`

**Feliratok/gombok (Caption):** KEZD · ID · dekanySoft · UTOLS · SZ · KIL · MAKEEXCEL · EXCEL T

## Eljárások / függvények (.pas)
`PenztarBeolvasas`, `Adatnullazas`, `ForgalomLegyujtes`, `Profitlegyujtes`, `WuLegyujtes`, `AfaLegyujtes`, `Ekerlegyujtes`, `Axalegyujtes`, `TranzadoLegyujtes`, `STARTGOMBClick`, `ESCAPEGOMBClick`, `DatumDisplay`, `TOLNAPTARClick`, `FormActivate`, `Vesszokivono`, `Forintform`, `Nulele`, `WideDatum`, `ScanKorzet`, `TForm1.FormActivate`, `TForm1.STARTGOMBClick`, `TForm1.ESCAPEGOMBClick`, `TForm1.TOLNAPTARClick`, `TForm1.AdatNullazas`, `TForm1.PenztarBeolvasas`, `TForm1.Vesszokivono`, `Tform1.ScanKorzet`, `TForm1.Nulele`, `TForm1.Forintform`, `Tform1.WideDatum`

## Érintett adatbázis-táblák
`IRODAK`

**SQL-műveletek (minta):**
- `SELECT * FROM IRODAK`
- `SELECT * FROM`
- `WHERE (DATUM>=`
- `WHERE (BIZONYLATSZAM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- A KEZDŐ-DÁTUM NAGYOBB AZ UTOLSÓ DÁTUMNÁL !
- AZ UTOLSÓ NAP MAXIMUMA A TEGNAPI NAP !

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
