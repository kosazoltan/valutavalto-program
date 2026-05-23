# Legacy modul: GETFIZE

> Forrás (primer): `Anti/VALUTA/DLL/GETFIZE/MAKEDLL/Unit2.pas` (3450 karakter) · library: `DLL/GETFIZE/MAKEDLL/Getfize.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`fizetoeszkozrutin`

## DFM form(ok) / képernyő
`TGETFIZETOESZKOZ`

**Feliratok/gombok (Caption):** GETFIZETOESZKOZ · FIZET · BANKK · A P · PR · BEL

## Eljárások / függvények (.pas)
`FormActivate`, `ValutaParancs`, `BKGOMBClick`, `KPGOMBClick`, `MEGSEMGOMBClick`, `BELEPGOMBClick`, `TGETFIZETOESZKOZ.FormActivate`, `TGETFIZETOESZKOZ.BKGOMBClick`, `TGETFIZETOESZKOZ.KPGOMBClick`, `TGETFIZETOESZKOZ.MEGSEMGOMBClick`, `TGETFIZETOESZKOZ.BELEPGOMBClick`, `TGetFizetoEszkoz.ValutaParancs`

## Érintett adatbázis-táblák
`HARDWARE`, `VTEMP`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `UPDATE VTEMP SET OTPFUNCTYPE=50`
- `UPDATE HARDWARE SET OTPOPEN=1`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
