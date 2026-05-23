# Legacy modul (SZERVER-FEJLESZT): MAKIRODA

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/makiroda/unit1.pas` (4296 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/makiroda/makiroda.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Irodak.dat k · IRODAK.DAT K · (Path: C:\RECEPTOR\MAIL\IRODAK)

## Eljárások / függvények (.pas)
`OneWordWrite`, `STARTTIMERTimer`, `FormActivate`, `AcIrodakFelirasa`, `TForm1.STARTTIMERTimer`, `TForm1.AcIrodakFelirasa`, `TForm1.OneWordWrite`, `TForm1.FormActivate`

## Érintett adatbázis-táblák
`IRODAK`

**SQL-műveletek (minta):**
- `SELECT * FROM IRODAK ORDER BY UZLET`
- `SELECT * FROM IRODAK`
- `WHERE CLOSED=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
