# Legacy modul: KEZDKEDV

> Forrás (primer): `Anti/VALUTA/DLL/KEZDKEDV/MAKEDLL/Unit2.pas` (9312 karakter) · library: `DLL/KEZDKEDV/MAKEDLL/KEZDKEDV.DPR`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`kezdijkedvezmeny`

## DFM form(ok) / képernyő
`TForm2`

**Feliratok/gombok (Caption):** Form2 · KEZEL · ENGED · AKCI · SPECI · EGYEDI KEZEL · 5 800  Ft · RENDBEN · KEDVEZM · Ft

## Eljárások / függvények (.pas)
`Button1Click`, `AlapAdatBeolvasas`, `PerMouseMove`, `ClearAll`, `TakaroFel`, `Finish`, `FormActivate`, `MEGSEMGOMBClick`, `ALAPLAPMouseMove`, `PERMHALFClick`, `FtForm`, `Label5Click`, `CARDNUMEDITKeyDown`, `PERMDELClick`, `Label7Click`, `KEZDIJEDITKeyDown`, `RENDBENGOMBClick`, `ValutaParancs`, `KILEPOTimer`, `kerekito`, `supervisorjelszo`, `TForm2.FormActivate`, `TForm2.PERMouseMove`, `TForm2.ClearAll`, `TForm2.Button1Click`, `TForm2.MEGSEMGOMBClick`, `TForm2.ALAPLAPMouseMove`, `TForm2.PERMHALFClick`, `TForm2.Finish`, `Tform2.FtForm`

## Érintett adatbázis-táblák
`HARDWARE`, `VTEMP`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM VTEMP`
- `UPDATE VTEMP SET KEZELESIDIJ=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- A napi egyedi kezdij lehetősége kimerült

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
