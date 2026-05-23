# Legacy modul: BIGARFVALT

> Forrás (primer): `Anti/VALUTA/DLL/BIGARFVALT/MAKEDLL/Unit2.pas` (10884 karakter) · library: `DLL/BIGARFVALT/MAKEDLL/BigArfValt.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`bigarfolyamkedvezmeny`

## DFM form(ok) / képernyő
`TForm2`

**Feliratok/gombok (Caption):** Form2 · .V · KEDVEZM · ELSZ · JELSZ · ENGED · MAGAS KEDVEZM · JELSZAVAS MEGER

## Eljárások / függvények (.pas)
`FormActivate`, `MEGSEMGOMBClick`, `Bigszazalekrutin`, `KEDVARFOLYAMEDITEnter`, `KEDVARFOLYAMEDITExit`, `AdatKijelzes`, `KILEPOTimer`, `Kparancs`, `KEDVARFOLYAMEDITKeyDown`, `JELSZOKEROGOMBClick`, `ENGEDELYGOMBClick`, `supervisorjelszo`, `TForm2.FormActivate`, `TForm2.MegsemGombClick`, `TForm2.KedvArfolyamEditEnter`, `TForm2.KedvArfolyamEditExit`, `Tform2.AdatKijelzes`, `TForm2.KilepoTimer`, `TForm2.KEDVARFOLYAMEDITKeyDown`, `TForm2.JelszokeroGombClick`, `TForm2.Bigszazalekrutin`, `TForm2.EngedelyGombClick`, `TForm2.KParancs`

## Érintett adatbázis-táblák
`VTEMP`

**SQL-műveletek (minta):**
- `SELECT * FROM VTEMP WHERE MEGJEGYZES=`
- `UPDATE VTEMP SET ARFOLYAM=`
- `WHERE VALUTANEM=`
- `UPDATE VTEMP SET RATETYPE=8`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
