# Legacy modul: DOCDISP

> Forrás (primer): `Anti/VALUTA/DLL/DOCDISP/MAKEDLL/Unit2.pas` (6022 karakter) · library: `DLL/DOCDISP/MAKEDLL/Docdisp.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`docdisprutin`

## DFM form(ok) / képernyő
`TForm2`

**Feliratok/gombok (Caption):** Form2 · AZ  · 12. DOCUMENTUM · EL · VISSZA

## Eljárások / függvények (.pas)
`Button1Click`, `FormActivate`, `BitBtn1Click`, `Image1Click`, `Image2Click`, `KILEPOTimer`, `Getalapadatok`, `DocKijelzo`, `ReadMWord`, `GetJPGSize`, `TForm2.Button1Click`, `TForm2.FormActivate`, `TForm2.DocKijelzo`, `TForm2.SetTakarok`, `TForm2.BitBtn1Click`, `TForm2.Image1Click`, `TForm2.Image2Click`, `TForm2.GetAlapAdatok`, `TForm2.KILEPOTimer`

## Érintett adatbázis-táblák
`VTEMP`

**SQL-műveletek (minta):**
- `SELECT * FROM VTEMP`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
