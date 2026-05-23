# Legacy modul: IDOSZAK

> Forrás (primer): `Anti/VALUTA/DLL/IDOSZAK/MAKEDLL/Unit2.pas` (7910 karakter) · library: `DLL/IDOSZAK/MAKEDLL/Idoszak.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`idoszakrutin`

## DFM form(ok) / képernyő
`THONAPKEROFORM`

**Feliratok/gombok (Caption):** HONAPKEROFORM · ADJA MEG A K · -T · -IG · ID · CSAK A MAI NAP

## Eljárások / függvények (.pas)
`Nulele`, `FormActivate`, `HoComboChange`, `IdszCancelGOMBClick`, `IdszOkeGombClick`, `IgNapComboChange`, `NapComboTolto`, `Adatrogzites`, `TolnapComboChange`, `ValutaParancs`, `FormCreate`, `IDSZOKEGOMBEnter`, `IDSZOKEGOMBExit`, `IDSZOKEGOMBMouseMove`, `MAINAPGOMBClick`, `THonapKeroForm.FormActivate`, `THonapKeroForm.IdszCancelGombClick`, `THonapKeroForm.HoComboChange`, `THonapKeroForm.IdszOkeGombClick`, `THonapKeroForm.AdatRogzites`, `THonapKeroForm.ValutaParancs`, `THonapKeroForm.NapComboTolto`, `THonapKeroForm.TolNapComboChange`, `THonapKeroForm.IgnapComboChange`, `THONAPKEROFORM.FormCreate`, `THONAPKEROFORM.IDSZOKEGOMBEnter`, `THONAPKEROFORM.IDSZOKEGOMBExit`, `THonapKeroForm.Nulele`, `THONAPKEROFORM.IDSZOKEGOMBMouseMove`, `THONAPKEROFORM.MAINAPGOMBClick`

## Érintett adatbázis-táblák
`IDOSZAK`

**SQL-műveletek (minta):**
- `DELETE FROM IDOSZAK`
- `INSERT INTO IDOSZAK (KERTEV,KERTHO,TOLNAP,IGNAP,TOLSTRING,IGSTRING)`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
