# Legacy modul (ÉRTÉKTÁR): KCIMLET

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/kcimlet/debug/unit2.pas` (20718 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/kcimlet/makedll/kcimlet.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`kcimletrutin`

## DFM form(ok) / képernyő
`TForm1`, `TForm2`

**Feliratok/gombok (Caption):** INDIT · KILEP · Form2 · USD · 20.000 · SS1 · 10.000 · SS2 · 5.000 · SS3 · 2.000 · SS4 · 1.000 · SS5 · 500 · SS6 · 200 · SS7 · 100 · SS8 · 50 · SS9 · 20 · SS10 · 10

## Eljárások / függvények (.pas)
`FormActivate`, `CimletElokeszites`, `TombeToltes`, `CimletNyomtatas`, `VonalHuzo`, `MegsemGombClick`, `CIMrogzitoGombClick`, `CimletDatabasebe`, `Cimletvegigszamolas`, `E1EditKeyDown`, `Kerekito`, `ForintForm`, `Tizenegy`, `negyes`, `Elokieg`, `E1EDITEnter`, `E1EDITExit`, `kcimletrutin`, `TForm2.FormActivate`, `TForm2.CimletElokeszites`, `TForm2.TombeToltes`, `TForm2.kerekito`, `TForm2.ForintForm`, `TFORM2.E1EDITKeyDown`, `TFORM2.MEGSEMGOMBClick`, `TFORM2.CIMrogzitoGOMBClick`, `Tform2.CimletNyomtatas`, `TForm2.CimletDatabasebe`, `TForm2.Cimletvegigszamolas`, `TForm2.VonalHuzo`

## Érintett adatbázis-táblák
`CIMLETPISZKOZAT`

**SQL-műveletek (minta):**
- `INSERT INTO CIMLETPISZKOZAT (VALUTANEM,BANKJEGY`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
