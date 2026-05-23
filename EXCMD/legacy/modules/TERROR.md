# Legacy modul: TERROR

> Forrás (primer): `Anti/VALUTA/DLL/TERROR/MAKEDLL/Unit2.pas` (7902 karakter) · library: `DLL/TERROR/MAKEDLL/terrlist.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`terrorcontrol`

## DFM form(ok) / képernyő
`TTERROR`

**Feliratok/gombok (Caption):** TERROR · AZ   · SZEREPEL AZ ENSZ · TERRORLIST · ENGED · TERRORLITSA ELLEN · Tranzakci

## Eljárások / függvények (.pas)
`FormActivate`, `KilepoTimer`, `Regisztracio`, `EngedelyGombClick`, `StopGombClick`, `EngedelyezoGombClick`, `EngedelyezoEditKeyDown`, `BetuKiemelo`, `logirorutin`, `supervisorjelszo`, `TTERROR.FormActivate`, `TTERROR.ENGEDELYGOMBClick`, `TTERROR.STOPGOMBClick`, `TTerror.Betukiemelo`, `TTerror.Regisztracio`, `TTERROR.ENGEDELYEZOGOMBClick`, `TTERROR.ENGEDELYEZOEDITKeyDown`, `TTerror.KilepoTimer`

## Érintett adatbázis-táblák
`HARDWARE`, `JOURNAL`, `PENZTAR`, `UNOLIST`, `VTEMP`

**SQL-műveletek (minta):**
- `SELECT * FROM VTEMP`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM UNOLIST WHERE TERROR_NAME LIKE`
- `INSERT INTO JOURNAL (DATUM,IDO,PENZTARKOD,PENZTARNEV,UGYFELNEV,`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
