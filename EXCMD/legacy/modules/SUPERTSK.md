# Legacy modul: SUPERTSK

> Forrás (primer): `Anti/VALUTA/DLL/SUPERTSK/MAKEDLL/Unit2.pas` (10104 karakter) · library: `DLL/SUPERTSK/MAKEDLL/SUPERTSK.DPR`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`supervisorrutin`

## DFM form(ok) / képernyő
`TSUPERVISORFORM`

**Feliratok/gombok (Caption):** SUPERVISORFORM · SUPERVISOR MEN · LOGFILE KIOLVAS · KIL · EXTRA TRANZAKCI · CHECKLISTA ELLEN · A P · MIKORT · MEDDIG · MEGNEVEZ · VISSZA · OTP TERMINAL LOG OVAS

## Eljárások / függvények (.pas)
`FormActivate`, `ESCAPEGOMBClick`, `NYITOGOMBEnter`, `NYITOGOMBExit`, `CIMLETSETUPGOMBClick`, `FormCreate`, `XTRANZGOMBClick`, `checklistgombClick`, `VISSZAGOMBClick`, `BitBtn4Click`, `BitBtn1Click`, `AlapadatBeolvasas`, `ValutaParancs`, `BitBtn5Click`, `checkcontrol`, `TSUPERVISORFORM.FormActivate`, `TSUPERVISORFORM.AlapadatBeolvasas`, `TSUPERVISORFORM.ESCAPEGOMBClick`, `TSUPERVISORFORM.NYITOGOMBEnter`, `TSUPERVISORFORM.NYITOGOMBExit`, `TSUPERVISORFORM.CIMLETSETUPGOMBClick`, `TSUPERVISORFORM.FormCreate`, `TSUPERVISORFORM.STORNOGOMBClick`, `TSUPERVISORFORM.DATUMOKEGOMBClick`, `TSUPERVISORFORM.MEGSEMGOMBClick`, `TSUPERVISORFORM.DATUMOKEGOMBEnter`, `TSUPERVISORFORM.DATUMOKEGOMBExit`, `TSUPERVISORFORM.EVKOMBOChange`, `TSUPERVISORFORM.LOGFILEBACKClick`, `TSUPERVISORFORM.XTRANZGOMBClick`

## Érintett adatbázis-táblák
`HARDWARE`, `PAUSES`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `DELETE FROM PAUSES WHERE (DATUM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
