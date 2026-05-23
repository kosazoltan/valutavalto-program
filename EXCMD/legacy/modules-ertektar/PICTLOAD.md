# Legacy modul (ÉRTÉKTÁR): PICTLOAD **[ÉRTÉKTÁR-EGYEDI — nincs VALUTA megfelelő]**

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/pictload/debug/unit2.pas` (3596 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/pictload/makedll/pictload.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`getcitypictures`

## DFM form(ok) / képernyő
`TForm1`, `TForm2`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · Form2

## Eljárások / függvények (.pas)
`INDITOTimer`, `KILEPOTimer`, `FTPszerverbeBelep`, `getcitypictures`, `TForm2.INDITOTimer`, `TForm2.KILEPOTimer`, `TForm2.FTPszerverbeBelep`

## Érintett adatbázis-táblák
`HARDWARE`

**SQL-műveletek (minta):**
- `SELECT* FROM HARDWARE`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
