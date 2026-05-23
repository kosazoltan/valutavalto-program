# Legacy modul (SZERVER-FEJLESZT): KDCHANGE

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/kdchange/unit1.pas` (2269 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/kdchange/project1.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · TRANZAKCI

## Eljárások / függvények (.pas)
`FormActivate`, `KParancs`, `KILEPOTimer`, `TForm1.FormActivate`, `TForm1.KParancs`, `TForm1.KILEPOTimer`

## Érintett adatbázis-táblák
`HARDWARE`, `TRANZDIJTABLA`

**SQL-műveletek (minta):**
- `UPDATE TRANZDIJTABLA SET TRANZAKCIO=`
- `WHERE SORSZAM=`
- `UPDATE TRANZDIJTABLA SET KEZELESIDIJ=`
- `WHERE SORSZAM=23`
- `UPDATE HARDWARE SET KEZDIJMAX=9990`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
