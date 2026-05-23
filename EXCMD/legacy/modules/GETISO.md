# Legacy modul: GETISO

> Forrás (primer): `Anti/VALUTA/DLL/GETISO/MAKEDLL/Unit2.pas` (6435 karakter) · library: `DLL/GETISO/MAKEDLL/GETISO.DPR`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`getisorutin`

## DFM form(ok) / képernyő
`TForm2`

**Feliratok/gombok (Caption):** Form2 · ORSZ

## Eljárások / függvények (.pas)
`Button1Click`, `FormActivate`, `VParancs`, `AdatBeolvasas`, `KILEPOTimer`, `COUNTRYMEGSEMGOMBClick`, `COUNTRYCOMBOChange`, `CITICOMBOChange`, `COUNTRYOKEGOMBClick`, `TForm2.Button1Click`, `TForm2.FormActivate`, `TForm2.Adatbeolvasas`, `TForm2.VParancs`, `TForm2.KILEPOTimer`, `TForm2.COUNTRYMEGSEMGOMBClick`, `TForm2.COUNTRYCOMBOChange`, `TForm2.CITICOMBOChange`, `TForm2.COUNTRYOKEGOMBClick`

## Érintett adatbázis-táblák
`CITIZENS`, `COUNTRIES`, `VTEMP`

**SQL-műveletek (minta):**
- `UPDATE VTEMP SET MEGJEGYZES=`
- `SELECT * FROM VTEMP`
- `SELECT * FROM COUNTRIES`
- `SELECT * FROM CITIZENS`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
