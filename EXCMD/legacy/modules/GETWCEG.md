# Legacy modul: GETWCEG

> Forrás (primer): `Anti/VALUTA/DLL/GETWCEG/MAKEDLL/Unit2.pas` (11286 karakter) · library: `DLL/GETWCEG/MAKEDLL/Getwceg.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`getwesternceg`

## DFM form(ok) / képernyő
`TGETWCEG`

**Feliratok/gombok (Caption):** GETWCEGFORM · KERESETT C · Western Union  · RENDBEN · UJ PARTNER · AZ 

## Eljárások / függvények (.pas)
`WCEGNEVEDITEnter`, `GetNextWudata`, `BackspaceRutin`, `WCEGNEVEDITExit`, `WCEGNEVEDITKeyDown`, `FormActivate`, `MEGSEMGOMBClick`, `RENDBENGOMBClick`, `UJCEGGOMBClick`, `WCEGRACSKeyDown`, `WCEGRACSKeyPress`, `kereseditEnter`, `CegetValasztott`, `RENDBENGOMBEnter`, `RENDBENGOMBExit`, `RENDBENGOMBMouseMove`, `WCEGRACSDblClick`, `WCEGRACSMouseMove`, `TGETWCEG.FormActivate`, `TGetWCeg.WCegRacsKeyDown`, `TGetWCeg.BackspaceRutin`, `TGetWCeg.WCegRacsKeyPress`, `TGETWCEG.WCEGNEVEDITEnter`, `TGETWCEG.WCEGNEVEDITExit`, `TGETWCEG.WCEGNEVEDITKeyDown`, `TGETWCEG.MEGSEMGOMBClick`, `TGETWCEG.RENDBENGOMBClick`, `TGETWCEG.UJCEGGOMBClick`, `TGETWCEG.kereseditEnter`, `TGetWCeg.Cegetvalasztott`

## Érintett adatbázis-táblák
`WUAFAADATOK`

**SQL-műveletek (minta):**
- `SELECT * FROM WUAFAADATOK`
- `UPDATE WUAFAADATOK SET`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
