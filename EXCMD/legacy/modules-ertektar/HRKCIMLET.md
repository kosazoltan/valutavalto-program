# Legacy modul (ÉRTÉKTÁR): HRKCIMLET **[ÉRTÉKTÁR-EGYEDI — nincs VALUTA megfelelő]**

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/hrkcimlet/debug/unit2.pas` (7623 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/hrkcimlet/makedll/hrkcim.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`kunacimletezes`

## DFM form(ok) / képernyő
`TForm1`, `TForm2`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · Form2 · HRK H · 1.000 · 500 · 200 · 100 · 50 · 20 · 10 · CIMLETEZETT · P1 · P2 · P3 · P4 · P5 · P6 · P7 · CIMLETEK RENDBEN · VISSZA A MEN

## Eljárások / függvények (.pas)
`FormActivate`, `Vegigszamol`, `E1Enter`, `E1Exit`, `KilepoTimer`, `TombBetoltes`, `CimOkeGombClick`, `CimMegsemGombClick`, `E1KeyDown`, `Ftform`, `TForm2.FormActivate`, `TForm2.Ftform`, `TForm2.E1KeyDown`, `TForm2.Vegigszamol`, `TForm2.E1Enter`, `TForm2.E1Exit`, `TForm2.TombBetoltes`, `TForm2.CIMOKEGOMBClick`, `TForm2.CIMMEGSEMGOMBClick`, `TForm2.KILEPOTimer`

## Érintett adatbázis-táblák
`HRKDATA`

**SQL-műveletek (minta):**
- `SELECT * FROM HRKDATA`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
