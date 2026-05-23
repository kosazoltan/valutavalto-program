# Legacy modul (ÉRTÉKTÁR): KESZUP

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/keszup/debug/unit2.pas` (13000 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/keszup/makedll/keszup.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`pillkeszletbekuldo`

## DFM form(ok) / képernyő
`TForm1`, `TKESZLETBEKULDO`

**Feliratok/gombok (Caption):** Form1 · INDUL · KIL · 0i

## Eljárások / függvények (.pas)
`FormActivate`, `KeszletBeolvasas`, `KeszletFeliras`, `Aktualkeszletek`, `Keszletkod`, `DnemKod`, `KILEPOTimer`, `ValutaParancs`, `Nul3`, `Scandnem`, `TKESZLETBEKULDO.FormActivate`, `TKESZLETBEKULDO.KeszletFeliras`, `TKeszletBekuldo.Nul3`, `TKESZLETBEKULDO.DnemKod`, `TKESZLETBEKULDO.Keszletkod`, `TKESZLETBEKULDO.kilepoTimer`, `TKeszletbekuldo.Scandnem`, `TKeszletbekuldo.ValutaParancs`, `TKeszletBekuldo.KeszletBeolvasas`, `TKeszletBekuldo.AktualKeszletek`

## Érintett adatbázis-táblák
`ARFOLYAM`, `EKERDATA`, `HARDWARE`, `KEZDIJDATA`, `PENZTAR`, `WUAFAADATOK`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM WUAFAADATOK`
- `SELECT * FROM EKERDATA`
- `SELECT * FROM KEZDIJDATA`
- `SELECT * FROM ARFOLYAM`
- `WHERE VALUTANEM<>`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
