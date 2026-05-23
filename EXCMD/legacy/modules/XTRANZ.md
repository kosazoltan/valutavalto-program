# Legacy modul: XTRANZ

> Forrás (primer): `Anti/VALUTA/DLL/XTRANZ/MAKEDLL/Unit2.pas` (9048 karakter) · library: `DLL/XTRANZ/MAKEDLL/Xtranz.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`extratranzdijdisp`

## DFM form(ok) / képernyő
`TXTRANZFORM`

**Feliratok/gombok (Caption):** XTRANZFORM · EGYEDI KEZEL · KIL · FORINT  · EGYEDI KEZ-D · NYOMTAT

## Eljárások / függvények (.pas)
`KILEPOGOMBClick`, `FormActivate`, `HONAPRENDBENGOMBClick`, `XKEZDIJRACSKeyUp`, `EVCOMBOChange`, `Nulele`, `BitBtn1Click`, `StartNyomtatas`, `Formazo`, `TXTRANZFORM.KILEPOGOMBClick`, `TXTRANZFORM.FormActivate`, `TXTRANZFORM.HONAPRENDBENGOMBClick`, `TXTRANZFORM.XKEZDIJRACSKeyUp`, `TXTRANZFORM.EVCOMBOChange`, `TXtranzForm.Nulele`, `TXTRANZFORM.BitBtn1Click`, `TXtranzForm.Formazo`, `TXtranzform.StartNyomtatas`

## Érintett adatbázis-táblák
`HARDWARE`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
