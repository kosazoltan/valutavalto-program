# Legacy modul (SZERVER-FEJLESZT): FRISSDAT

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/frissdat/unit1.pas` (14210 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/frissdat/frissdat.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Mikor frissitettek a p · Verzio: · 00.00 · Kil · 18 · 35 · 52 · 69 · 86 · 103 · 120 · 137 · 154 · 19 · 12 · 10 · 11 · 15 · 13 · 16 · 17 · 14 · 23 · 42 · 58

## Eljárások / függvények (.pas)
`FormActivate`, `PenztarBeolvasas`, `quitgombClick`, `SetTombok`, `DispCiklus`, `CIKLUSTimer`, `VERZIOCOMBOChange`, `VERZIOVALTOGOMBClick`, `P1MouseMove`, `KOCKAPANELMouseMove`, `TForm1.FormActivate`, `TForm1.quitgombClick`, `TForm1.PenztarBeolvasas`, `tform1.dispciklus`, `TForm1.setTombok`, `TForm1.CIKLUSTimer`, `TForm1.VERZIOCOMBOChange`, `TForm1.VERZIOVALTOGOMBClick`, `TForm1.P1MouseMove`, `TForm1.KOCKAPANELMouseMove`

## Érintett adatbázis-táblák
`FRISSITESEK`, `IRODAK`

**SQL-műveletek (minta):**
- `SELECT * FROM FRISSITESEK`
- `SELECT * FROM IRODAK`
- `WHERE CLOSED=`
- `WHERE VERZIO=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
