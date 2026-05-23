# Legacy modul (ÉRTÉKTÁR): REGIZARO

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/regizaro/debug/unit2.pas` (5998 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/regizaro/makedll/regizaro.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`regizarasrutin`

## DFM form(ok) / képernyő
`TForm1`, `TREGIZARASFORM`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · REGIZARASFORM · EGY R · NYOMTAT

## Eljárások / függvények (.pas)
`ESCAPEGOMBClick`, `FormActivate`, `EVCOMBOChange`, `NAPCOMBOChange`, `DatumAllito`, `STARTGOMBClick`, `ValutaParancs`, `Nulele`, `supervisorjelszo`, `TREGIZARASFORM.FormActivate`, `TREGIZARASFORM.ValutaParancs`, `TREGIZARASFORM.ESCAPEGOMBClick`, `TREGIZARASFORM.EVCOMBOChange`, `TREGIZARASFORM.NAPCOMBOChange`, `TRegizarasForm.DAtumAllito`, `TREGIZARASFORM.STARTGOMBClick`, `TRegizarasForm.Nulele`

## Érintett adatbázis-táblák
`VTEMP`

**SQL-műveletek (minta):**
- `DELETE FROM VTEMP`
- `INSERT INTO VTEMP (DATUM)`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
