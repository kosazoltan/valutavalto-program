# Legacy modul (ÉRTÉKTÁR): BIZODISP

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/bizodisp/debug/unit2.pas` (23792 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/bizodisp/makedll/bizodisp.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`bizonylattallozo`

## DFM form(ok) / képernyő
`TForm1`, `TBIZONYLATDISP`, `TForm3`

**Feliratok/gombok (Caption):** Form1 · Button1 · Button2 · BIZONYLATDISP · Blokk fejek · BIZONYLAT · BLOKK (FT) · VALUTA · FORINT · PARTNER P · BANK MEGNEVEZ · VAGY · SZ · MEGNEVEZ · Blokkt · 2013 szeptember 23 · El · Panel2 · STORNO BIZONYLATOK · AZ  · STORNOZOTT BIZONYLATOK · Bizonylat  · Vissza a f · BIZONYLATOK SZ · Sz

## Eljárások / függvények (.pas)
`FormActivate`, `VISSZAGOMBClick`, `FejrekordValtozott`, `StornoKijelzo`, `MindentLezar`, `MainapDisplay`, `Setcondi`, `Ujranyomtatas`, `DatumKiertekeles`, `Nulele`, `BlokktipusKijelzo`, `NAPTARChange`, `BLOKKFEJRACSKeyUp`, `BLOKKFEJRACSCellClick`, `BLOKKFEJRACSDblClick`, `PenztarBetoltes`, `PenztarKijelzo`, `ScanPenztar`, `Button1Click`, `BitBtn1Click`, `ValutaParancs`, `VTempKitoltes`, `INDOKEDITKeyDown`, `INDOKEDITExit`, `GetReprintIndok`, `HunDatetostr`, `ATVETGOMBClick`, `KOVHOGOMBClick`, `ELOHOGOMBClick`, `supervisorjelszo`

## Érintett adatbázis-táblák
`BLOKKFEJ`, `PENZTAR`, `VTEMP`, `WPENZSZALLITAS`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `WHERE (DATUM=`
- `WHERE BIZONYLATSZAM=`
- `SELECT * FROM BLOKKFEJ`
- `WHERE`
- `SELECT * FROM PENZTAR`
- `DELETE FROM VTEMP`
- `INSERT INTO VTEMP (VALUTANEM,ARFOLYAM,`
- `SELECT * FROM WPENZSZALLITAS`
- `UPDATE VTEMP SET BIZONYLATSZAM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- Nincs adat a kért hónapról
- A kért napról nincsenek adataim az adott feltételek mellett!
- A kért napról nincsenek adataim !

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
