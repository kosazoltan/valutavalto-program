# Legacy modul (SZERVER-FEJLESZT): NEWYEAR

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/newyear/unit1.pas` (11388 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/newyear/project1.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · 2021

## Eljárások / függvények (.pas)
`Dirdel`, `Zap`, `fCopy`, `rCopy`, `SParancs`, `TParancs`, `KilepoTimer`, `FormActivate`, `SigCopy`, `TForm1.FormActivate`, `TForm1.Dirdel`, `TForm1.Zap`, `TForm1.fCopy`, `TForm1.RCopy`, `TForm1.SigCopy`, `TForm1.SParancs`, `TForm1.TParancs`, `TForm1.KILEPOTimer`

## Érintett adatbázis-táblák
`ADATOK`

**SQL-műveletek (minta):**
- `UPDATE ADATOK SET UTSORSZAM=0,UTVIPSORSZAM=0,UTZALOGSORSZAM=0`
- `DELETE FROM`
- `SELECT * FROM`
- `INSERT INTO`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
