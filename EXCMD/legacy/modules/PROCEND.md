# Legacy modul: PROCEND

> Forrás (primer): `Anti/VALUTA/DLL/PROCEND/MAKEDLL/Unit2.pas` (2708 karakter) · library: `DLL/PROCEND/MAKEDLL/Procend.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`procendrutin`

## DFM form(ok) / képernyő
`TPROCENDFORM`

**Feliratok/gombok (Caption):** NYOMJON EGY SPACE-T !

## Eljárások / függvények (.pas)
`FormActivate`, `AktualNullazo`, `Panel1Click`, `HIDEEDITKeyPress`, `HIDEEDITEnter`, `HIDEEDITExit`, `TProcEndForm.FormActivate`, `TProcEndForm.AktualNullazo`, `TProcEndForm.Panel1Click`, `TProcEndForm.HIDEEDITKeyPress`, `TProcEndForm.HIDEEDITEnter`, `TProcEndForm.HIDEEDITExit`

## Érintett adatbázis-táblák
`UTOLSOBLOKKOK`

**SQL-műveletek (minta):**
- `UPDATE UTOLSOBLOKKOK SET AKTUALISBIZONYLATSZAM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
