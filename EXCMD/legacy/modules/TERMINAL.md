# Legacy modul: TERMINAL

> Forrás (primer): `Anti/VALUTA/DLL/TERMINAL/MAKEDLL/Unit2.pas` (3006 karakter) · library: `DLL/TERMINAL/MAKEDLL/Terminal.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`terminalrutin`

## DFM form(ok) / képernyő
`TTERMINALFORM`

**Feliratok/gombok (Caption):** TERMINALFORM · TERMINAL · VISSZA A MEN

## Eljárások / függvények (.pas)
`FormActivate`, `VISSZAGOMBClick`, `AlapAdatBeolvasas`, `TTerminalForm.FormActivate`, `TTERMINALFORM.Alapadatbeolvasas`, `TTERMINALFORM.VISSZAGOMBClick`

## Érintett adatbázis-táblák
`HARDWARE`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
