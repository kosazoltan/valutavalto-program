# Legacy modul (ÉRTÉKTÁR): GETELLEN **[ÉRTÉKTÁR-EGYEDI — nincs VALUTA megfelelő]**

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/getellen/debug/unit2.pas` (3191 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/getellen/makedll/getellen.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`getellenorrutin`

## DFM form(ok) / képernyő
`TForm1`, `TGETELLENOR`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · GETELLENOR · NEVE: · BEOSZT · ( A z · ELLEN

## Eljárások / függvények (.pas)
`FormActivate`, `NEVEDITEnter`, `NEVEDITExit`, `BEOEDITKeyDown`, `RENDBENGOMBClick`, `MEGSEMGOMBClick`, `ValutaParancs`, `NEVEDITKeyDown`, `TGETELLENOR.FormActivate`, `TGETELLENOR.NEVEDITEnter`, `TGETELLENOR.NEVEDITExit`, `TGETELLENOR.MEGSEMGOMBClick`, `TGetEllenor.ValutaParancs`, `TGETELLENOR.NEVEDITKeyDown`, `TGetEllenor.BeoEditKeyDown`, `TGETELLENOR.RENDBENGOMBClick`

## Érintett adatbázis-táblák
`VTEMP`

**SQL-műveletek (minta):**
- `UPDATE VTEMP SET ELLENORNEV=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
