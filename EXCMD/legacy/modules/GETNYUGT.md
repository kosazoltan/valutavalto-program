# Legacy modul: GETNYUGT

> Forrás (primer): `Anti/VALUTA/DLL/GETNYUGT/MAKEDLL/Unit2.pas` (5493 karakter) · library: `DLL/GETNYUGT/MAKEDLL/Getnyug.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`getnyugtarutin`

## DFM form(ok) / képernyő
`TGETNYUGTA`

**Feliratok/gombok (Caption):** A P · NEM JELZETT VISSZA · NEM NYOMTATOTT NYUGT · NYUGTASZ · NYUGT · TOV

## Eljárások / függvények (.pas)
`FormActivate`, `NYOKEGOMBClick`, `RECNUMEDITKeyUp`, `ZCOUNTEDITKeyUp`, `SorszamFeliro`, `TOVABBGOMBClick`, `NINCSNYUGTAGOMBClick`, `supervisorjelszo`, `TGETNYUGTA.FormActivate`, `TGETNYUGTA.ZCOUNTEDITKeyUp`, `TGETNYUGTA.RECNUMEDITKeyUp`, `TGETNYUGTA.NYOKEGOMBClick`, `TGetnyugta.SorszamFeliro`, `TGETNYUGTA.TOVABBGOMBClick`, `TGETNYUGTA.NINCSNYUGTAGOMBClick`

## Érintett adatbázis-táblák
`VTEMP`

**SQL-műveletek (minta):**
- `UPDATE VTEMP SET ZCOUNTS=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
