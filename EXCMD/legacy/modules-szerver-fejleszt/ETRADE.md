# Legacy modul (SZERVER-FEJLESZT): ETRADE

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/etrade/unit1.pas` (11374 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/etrade/etrade.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · E-TRADE ADATOK · BEDOLGOZ

## Eljárások / függvények (.pas)
`FormActivate`, `KILEPOTimer`, `Beregiszt`, `Regisztralas`, `CreateEtabla`, `ErtektarBeolvasas`, `Hzelemzes`, `Havizaras`, `HZTablaMake`, `Nulele`, `RealToStr`, `scanIroda`, `ScanHzar`, `TForm1.FormActivate`, `TForm1.KILEPOTimer`, `TForm1.Beregiszt`, `TForm1.Regisztralas`, `TForm1.CreateEtabla`, `TForm1.Nulele`, `TFORM1.RealToStr`, `TForm1.ErtektarBeolvasas`, `Tform1.scanIroda`, `TForm1.Hzelemzes`, `TForm1.ScanHzar`, `TForm1.Havizaras`, `TForm1.HztablaMake`

## Érintett adatbázis-táblák
`IRODAK`

**SQL-műveletek (minta):**
- `DELETE FROM`
- `WHERE (DATUM=`
- `INSERT INTO`
- `SELECT * FROM IRODAK`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
