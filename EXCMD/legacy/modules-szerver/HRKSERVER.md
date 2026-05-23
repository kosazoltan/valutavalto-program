# Legacy modul (SZERVER): HRKSERVER

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/hrkserver/debug/unit2.pas` (40083 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/hrkserver/makedll/hrk.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`horvatkunarutinok`

## DFM form(ok) / képernyő
`TForm1`, `TForm2`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · Form2 · EGY HAVI HORV · VALUTANEM: · 2023 febru · 1. · 2. · 3. · 4. · 5. · 6. · 7. · 8. · 9. · 10. · 11. · 12. · 13. · 14. · 15. · 16. · 17. · 18.

## Eljárások / függvények (.pas)
`FormActivate`, `IdoszakBeolvasas`, `MakePenztarsor`, `MakeExcel`, `Vekony`, `Vastag`, `PenztarAdatOLvasas`, `HrkParancs`, `Adatbeiras`, `MakeWorkPlace`, `HrkLegyujtes`, `ExcelZaro`, `KillExcel`, `HrkRacsDisplay`, `HufRacsDisplay`, `AdatSummazas`, `Nullazas`, `RekordValtas`, `KILEPOTimer`, `ScanKorzet`, `Getkorzetnev`, `EXCELGOMBClick`, `KILEPOGOMBClick`, `HRKHUFGOMBClick`, `PENZTARGOMBClick`, `KORZETGOMBClick`, `CHANGEGOMBClick`, `HRKRACSCellClick`, `HRKRACSDblClick`, `HRKRACSKeyUp`

## Érintett adatbázis-táblák
`IDOSZAK`, `IRODAK`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `WHERE (VALUTANEM=`
- `SELECT * FROM IDOSZAK`
- `SELECT * FROM IRODAK WHERE UZLET=`
- `DELETE FROM`
- `INSERT INTO`
- `WHERE PENZTARSZAM>0`
- `WHERE (PENZTARSZAM>0)`
- `WHERE (PENZTARSZAM=0) AND (`
- `WHERE (PENZTARSZAM=0) AND (ERTEKTAR=0)`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
