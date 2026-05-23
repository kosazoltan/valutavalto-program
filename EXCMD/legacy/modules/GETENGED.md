# Legacy modul: GETENGED

> Forrás (primer): `Anti/VALUTA/DLL/GETENGED/MAKEDLL/Unit2.pas` (10046 karakter) · library: `DLL/GETENGED/MAKEDLL/getenged.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`getengedelyrutin`

## DFM form(ok) / képernyő
`TForm2`

**Feliratok/gombok (Caption):** Form2 · TRANZAKCI · A p · Egy · Enged · Az  · Nem enged · AZ  · RENDELKEZ · IGEN · NEM

## Eljárások / függvények (.pas)
`FormActivate`, `ENGEDELYEZOEDITEnter`, `ENGEDELYEZOEDITExit`, `ENGEDELYEZOEDITKeyDown`, `FORRASCOMBOChange`, `EGYEBEDITKeyDown`, `MEGSEMGOMBClick`, `RENDBENGOMBClick`, `ValutaParancs`, `NOGOMBClick`, `YESGOMBClick`, `KILEPOTimer`, `getengedelyrutin`, `TForm2.FormActivate`, `TForm2.ENGEDELYEZOEDITEnter`, `TForm2.ENGEDELYEZOEDITExit`, `TForm2.ENGEDELYEZOEDITKeyDown`, `TForm2.FORRASCOMBOChange`, `Tform2.ValutaParancs`, `TForm2.EGYEBEDITKeyDown`, `TForm2.MEGSEMGOMBClick`, `TForm2.RENDBENGOMBClick`, `TForm2.NOGOMBClick`, `TForm2.YESGOMBClick`, `TForm2.KILEPOTimer`

## Érintett adatbázis-táblák
`VTEMP`

**SQL-műveletek (minta):**
- `UPDATE VTEMP SET ENGEDELYEZO=`
- `UPDATE VTEMP SET FORRAS=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
