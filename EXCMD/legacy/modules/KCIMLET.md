# Legacy modul: KCIMLET

> Forrás (primer): `Anti/VALUTA/DLL/KCIMLET/MAKEDLL/Unit2.pas` (21308 karakter) · library: `DLL/KCIMLET/MAKEDLL/Kcimlet.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`kcimletrutin`

## DFM form(ok) / képernyő
`TForm2`

**Feliratok/gombok (Caption):** Form2 · USD · 20.000 · SS1 · 10.000 · SS2 · 5.000 · SS3 · 2.000 · SS4 · 1.000 · SS5 · 500 · SS6 · 200 · SS7 · 100 · SS8 · 50 · SS9 · 20 · SS10 · 10 · SS11 · SS12

## Eljárások / függvények (.pas)
`FormActivate`, `CimletElokeszites`, `TombeToltes`, `CimletNyomtatas`, `VonalHuzo`, `MegsemGombClick`, `CIMrogzitoGombClick`, `CimletDatabasebe`, `Cimletvegigszamolas`, `E1EditKeyDown`, `Kerekito`, `ForintForm`, `Tizenegy`, `negyes`, `Elokieg`, `E1EDITEnter`, `E1EDITExit`, `kcimletrutin`, `TForm2.FormActivate`, `TForm2.CimletElokeszites`, `TForm2.TombeToltes`, `TForm2.kerekito`, `TForm2.ForintForm`, `TFORM2.E1EDITKeyDown`, `TFORM2.MEGSEMGOMBClick`, `TFORM2.CIMrogzitoGOMBClick`, `Tform2.CimletNyomtatas`, `TForm2.CimletDatabasebe`, `TForm2.Cimletvegigszamolas`, `TForm2.VonalHuzo`

## Érintett adatbázis-táblák
`CIMLETPISZKOZAT`

**SQL-műveletek (minta):**
- `INSERT INTO CIMLETPISZKOZAT (VALUTANEM,VALUTANEV,BANKJEGY`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
