# Legacy modul: REGIZARO

> Forrás (primer): `Anti/VALUTA/DLL/REGIZARO/MAKEDLL/Unit2.pas` (5720 karakter) · library: `DLL/REGIZARO/MAKEDLL/REGIZARO.DPR`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`regizarasrutin`

## DFM form(ok) / képernyő
`TREGIZARASFORM`

**Feliratok/gombok (Caption):** REGIZARASFORM · EGY R · NYOMTAT

## Eljárások / függvények (.pas)
`ESCAPEGOMBClick`, `FormActivate`, `EVCOMBOChange`, `NAPCOMBOChange`, `DatumAllito`, `STARTGOMBClick`, `ValutaParancs`, `Nulele`, `TREGIZARASFORM.FormActivate`, `TREGIZARASFORM.ValutaParancs`, `TREGIZARASFORM.ESCAPEGOMBClick`, `TREGIZARASFORM.EVCOMBOChange`, `TREGIZARASFORM.NAPCOMBOChange`, `TRegizarasForm.DAtumAllito`, `TREGIZARASFORM.STARTGOMBClick`, `TRegizarasForm.Nulele`

## Érintett adatbázis-táblák
`VTEMP`

**SQL-műveletek (minta):**
- `DELETE FROM VTEMP`
- `INSERT INTO VTEMP (DATUM)`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
