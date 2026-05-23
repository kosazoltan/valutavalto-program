# Legacy modul: CONFIRM

> Forrás (primer): `Anti/VALUTA/DLL/CONFIRM/MAKEDLL/Unit2.pas` (3103 karakter) · library: `DLL/CONFIRM/MAKEDLL/confirm.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`confirmrutin`

## DFM form(ok) / képernyő
`TCONFIRMFORM`

**Feliratok/gombok (Caption):**                 Tranzakci · TRANZAKCI · IGEN · NEM

## Eljárások / függvények (.pas)
`FormActivate`, `IGENGOMBClick`, `NEMGOMBClick`, `TCONFIRMFORM.FormActivate`, `TCONFIRMFORM.IGENGOMBClick`, `TCONFIRMFORM.NEMGOMBClick`

## Érintett adatbázis-táblák
`VTEMP`

**SQL-műveletek (minta):**
- `SELECT * FROM VTEMP`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
