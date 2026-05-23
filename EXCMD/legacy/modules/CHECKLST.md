# Legacy modul: CHECKLST

> Forrás (primer): `Anti/VALUTA/DLL/CHECKLST/MAKEDLL/Unit2.pas` (13576 karakter) · library: `DLL/CHECKLST/MAKEDLL/Checklst.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`checkcontrol`

## DFM form(ok) / képernyő
`TTASKCTRL`

**Feliratok/gombok (Caption):** VISSZA A F · 2013.11.05 · 2013.02.22 · el · NYOMTAT · VISSZA A MEN

## Eljárások / függvények (.pas)
`Sorjeloles`, `Oszlopixelo`, `ChangeCheckJel`, `FormActivate`, `Edit1MouseMove`, `Edit1Exit`, `VISSZAGOMBClick`, `SuperControl`, `NAPTARChange`, `Label5Click`, `ELOZOHOClick`, `KOVETKEZOHOClick`, `NAPTARDblClick`, `Gepadatok`, `Edit1Click`, `ROGZITOGOMBClick`, `NYOMTATOGOMBClick`, `KILEPOTimer`, `Hundatetostr`, `Nulele`, `checkcontrol`, `supervisorjelszo`, `TTASKCTRL.FormActivate`, `TTASKCTRL.Supercontrol`, `TTASKCTRL.Edit1MouseMove`, `TTASKCTRL.Sorjeloles`, `TTASKCTRL.Edit1Exit`, `TTASKCTRL.VISSZAGOMBClick`, `TTASKCTRL.NAPTARChange`, `TTASKCTRL.Label5Click`

## Érintett adatbázis-táblák
`HARDWARE`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`

## Felhasználói üzenetek (üzleti szabály-jelek)
- A KÉRT NAPRÓL NINCS CHECKLISTA
- A NAPI CHECKFILE MÁR RÖGZITVE VAN !
- A CSEKKLISTÁT SIKERESEN RÖGZITETTEM

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
