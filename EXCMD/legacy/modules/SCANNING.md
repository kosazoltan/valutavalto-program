# Legacy modul: SCANNING

> Forrás (primer): `Anti/VALUTA/DLL/SCANNING/MAKEDLL/Unit2.pas` (6893 karakter) · library: `DLL/SCANNING/MAKEDLL/SCANNING.DPR`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`bescannelorutin`

## DFM form(ok) / képernyő
`TForm2`

**Feliratok/gombok (Caption):** Form2 · Siker · Igen - Sikeresen beolvastam · Nem siker · FELK

## Eljárások / függvények (.pas)
`FormActivate`, `SCANOKEGOMBClick`, `CANCELGOMBClick`, `RETRYGOMBClick`, `AdatBeolvasas`, `ScanMenet`, `VegrehajtEsVar`, `WinExecAndWait32`, `TForm2.FormActivate`, `TForm2.ScanMenet`, `TFORM2.WinExecAndWait32`, `TForm2.Adatbeolvasas`, `TForm2.SCANOKEGOMBClick`, `TForm2.CANCELGOMBClick`, `TForm2.RETRYGOMBClick`, `TForm2.VegrehajtEsVar`

## Érintett adatbázis-táblák
`VTEMP`

**SQL-műveletek (minta):**
- `SELECT * FROM VTEMP`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
