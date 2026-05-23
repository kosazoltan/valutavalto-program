# Legacy modul (SZERVER-FEJLESZT): OKMCTRL

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/okmctrl/unit1.pas` (12363 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/okmctrl/okmctrl.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** HI · START · KIL

## Eljárások / függvények (.pas)
`KILEPOGOMBClick`, `TaroltJpgTombbe`, `OkmParancs`, `IrodanevBetoltes`, `STARTGOMBClick`, `FormActivate`, `DATUMEDITEnter`, `DATUMEDITExit`, `DATUMEDITKeyDown`, `JpegInsert`, `TForm1.FormActivate`, `TForm1.KILEPOGOMBClick`, `TForm1.STARTGOMBClick`, `TForm1.Hasonlitas`, `TForm1.DATUMEDITEnter`, `TForm1.DATUMEDITExit`, `TForm1.DATUMEDITKeyDown`, `TForm1.TaroltJpgTombbe`, `TForm1.JpegInsert`, `TForm1.IrodanevBetoltes`

## Érintett adatbázis-táblák
`IRODAK`, `OKMANYHIANY`

**SQL-műveletek (minta):**
- `DELETE FROM OKMANYHIANY`
- `SELECT * FROM`
- `WHERE (DATUM>=`
- `WHERE SORSZAM=`
- `INSERT INTO OKMANYHIANY (SORSZAM,NEV,PENZTAR,`
- `SELECT * FROM OKMANYHIANY`
- `WHERE (SORSZAM=`
- `SELECT * FROM IRODAK`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
