# Legacy modul (ÉRTÉKTÁR): ESTIZAR

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/estizar/debug/unit1.pas` (54542 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/estizar/makedll/estizar.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`estizaraskuldes`

## DFM form(ok) / képernyő
`TForm1`, `TMAKEPACK`

**Feliratok/gombok (Caption):** Form1 · Button1 · Button2 · Egy napi z · NAPI Z · MELYIK NAP Z · << el · CSOMAGOL · 2012 szeptember · Csomag felir

## Eljárások / függvények (.pas)
`Button2Click`, `Button1Click`, `TForm1.Button2Click`, `TForm1.Button1Click`, `TEstiZar.FormActivate`, `TEstiZar.NapZCancelClick`, `TEstiZar.CsomagoloGombClick`, `TestiZar.EgyTablaKodolas`, `Testizar.BlokKTetelKodolas`, `TestiZar.Beiras`, `TestiZar.ClearOutDir`, `TestiZar.ByteDekod`, `TEstizar.IrodaKod`, `TEstizar.DnemKod`, `TEstizar.MatricaKodolas`, `TEstizar.MatPackIro`, `TEstizar.KezdijPackiro`, `TEstizar.FoglaloKodolas`, `TEstizar.XkezdijKodolas`, `TEstizar.JelenletKodolas`, `TEstizar.Etarmatcsomag`, `Testizar.AppendPersonalData`, `TEstizar.Ugyfelkodolas`, `TEstizar.AdatlapKodolas`, `TEstizar.Gongycsomagkodolas`, `TESTIZAR.ELOHOGOMBClick`, `TESTIZAR.KOVHOGOMBClick`, `TEstiZar.HonapDisplay`, `TESTIZAR.NEGSEMZARGOMBClick`

## Érintett adatbázis-táblák
`ADATLAP`, `CIMT`, `FOGLALOKESZLET`, `GONGYCSOMAG`, `JOGISZEMELY`, `MATBIZONYLAT`, `NAPIKEZELESIDIJ`, `NAPIMAT`, `NAPIOSSZESITO`, `UGYFEL`

**SQL-műveletek (minta):**
- `WHERE (DATUM=`
- `SELECT * FROM CIMT`
- `SELECT * FROM`
- `SELECT FEJ.*, TET.*`
- `FROM`
- `WHERE (FEJ.DATUM=`
- `SELECT * FROM NAPIOSSZESITO`
- `WHERE DATUM=`
- `SELECT * FROM FOGLALOKESZLET`
- `SELECT * FROM NAPIMAT`
- `SELECT * FROM MATBIZONYLAT`
- `SELECT * FROM JOGISZEMELY`

## Felhasználói üzenetek (üzleti szabály-jelek)
- Nem volt cimletezés a kért napon !

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
