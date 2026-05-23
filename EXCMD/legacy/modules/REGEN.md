# Legacy modul: REGEN

> Forrás (primer): `Anti/VALUTA/DLL/REGEN/MAKEDLL/Unit2.pas` (37405 karakter) · library: `DLL/REGEN/MAKEDLL/REGEN.DPR`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`regeneralorutin`

## DFM form(ok) / képernyő
`TREGENERALO`

**Feliratok/gombok (Caption):** A PILLANATNYI  · A WESTERN UNION · REGENER

## Eljárások / függvények (.pas)
`FormActivate`, `IdozitoTimer`, `PillAllRegen`, `WuniRegen`, `DnemTolto`, `ForgalomBedolgozas`, `NyitoBetoltes`, `EgyenlegBemasolas`, `WuniNyitoBe`, `WuniMozgasBe`, `MetroMozgasBe`, `TescoMozgasBe`, `KezdijRegeneralo`, `Kezdijregister`, `HianyzoBizonylat`, `RontottJeloles`, `TombbeOlvasas`, `iBParancs`, `GetHardwareData`, `Nulele`, `Kerekites`, `Dnemscan`, `RealToStr`, `Scanbiz`, `HunDatetostr`, `regeneralorutin`, `TREGENERALO.FormActivate`, `TRegeneralo.IdozitoTimer`, `TRegeneralo.PillAllRegen`, `TRegeneralo.NyitoBetoltes`

## Érintett adatbázis-táblák
`ARFOLYAM`, `BLOKKFEJ`, `HARDWARE`, `HAVIKEZELESIDIJ`, `KEZELESIDATA`, `KEZELESIDIJ`, `NAPIKEZELESIDIJ`, `WUAFAADATOK`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `WHERE STORNO=1`
- `SELECT FEJ.*,TET.*`
- `FROM`
- `WHERE FEJ.STORNO=1`
- `UPDATE ARFOLYAM`
- `WHERE VALUTANEM=`
- `UPDATE HARDWARE SET BANKKARTYA=`
- `DELETE FROM`
- `INSERT INTO`
- `UPDATE WUAFAADATOK SET WUDOLLARKESZLET=`
- `WHERE STORNO<2`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
