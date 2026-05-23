# Legacy modul: QUITFORM

> Forrás (primer): `Anti/VALUTA/DLL/QUITFORM/MAKEDLL/Unit2.pas` (10471 karakter) · library: `DLL/QUITFORM/MAKEDLL/QUITFORM.DPR`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`quitrutin`

## DFM form(ok) / képernyő
`TQUITFORM`

**Feliratok/gombok (Caption):** QUITFORM · KIL · HOLNAP NYITVA LESZ A P · IGEN, NYITVA  LESZ · NEM, Z · BIZTOS, HOGY KIL

## Eljárások / függvények (.pas)
`FormActivate`, `NyilatkozatNyomtato`, `EzSzombat`, `NyitvaVagy`, `NONQUITGOMBClick`, `QUITGOMBClick`, `SetPara`, `QUITTIMERTimer`, `NYITVAGOMBClick`, `ZARVAGOMBClick`, `ValutaParancs`, `Ezpentek`, `KozepreIr`, `StrtoHunDate`, `backuprestore`, `TQUITFORM.FormActivate`, `TQuitform.ValutaParancs`, `TQuitForm.Nyitvavagy`, `TQUITFORM.NONQUITGOMBClick`, `TQUITFORM.QUITGOMBClick`, `TQUITFORM.QUITTIMERTimer`, `TQuitForm.Ezpentek`, `TQuitform.EzSzombat`, `TQuitForm.NyilatkozatNyomtato`, `TQuitForm.KozepreIr`, `TQUITFORM.NYITVAGOMBClick`, `TQUITFORM.ZARVAGOMBClick`, `TQuitForm.StrtoHunDate`, `TQuitform.setpara`

## Érintett adatbázis-táblák
`HARDWARE`, `PENZTAR`, `VTEMP`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `DELETE FROM VTEMP`
- `UPDATE VTEMP SET DATUM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
