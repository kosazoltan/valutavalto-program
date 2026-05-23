# Legacy modul: KORLEV

> Forrás (primer): `Anti/VALUTA/DLL/KORLEV/MAKEDLL/Unit2.pas` (25959 karakter) · library: `DLL/KORLEV/MAKEDLL/korlev.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`korlevelrutin`

## DFM form(ok) / képernyő
`TKORLEVEL`, `TForm2`, `TForm1`

**Feliratok/gombok (Caption):** KORLEVEL · A LET · IKTAT · LEV · KIL · bet · Form2 · Form1 · irst

## Eljárások / függvények (.pas)
`AlapAdatBeolvasas`, `ArchiveGombClick`, `BitBtn1Click`, `EgyNyelv`, `FormCreate`, `FormActivate`, `KilepoTimer`, `KorlevelLetoltes`, `KorlevelOlvasas`, `Korparancs`, `LastYearGombClick`, `LeveletValasztott`, `LevelRegisztralas`, `LevelRacsDblClick`, `LevelRacsKeyDown`, `MessKijelzes`, `OlvasoGombClick`, `Readregist`, `Hundatetostr`, `Korleveldownload`, `Nulele`, `WinExecAndWait32`, `korlevelrutin`, `TKORLEVEL.FormActivate`, `TKorlevel.KorlevelLetoltes`, `TKorlevel.Korleveldownload`, `TKorlevel.LevelRegisztralas`, `TKorlevel.KorlevelOlvasas`, `TKORLEVEL.OLVASOGOMBClick`, `TKORLEVEL.LEVELRACSDblClick`

## Érintett adatbázis-táblák
`ADATOK`, `ARCHIVE`, `HARDWARE`, `IKTATO`, `KORLEVEL`, `LASTYEAR`, `PARAMETERS`, `PENZTAR`, `PENZTAROSOK`, `SIGNAL`, `ZALOGLEVEL`

**SQL-műveletek (minta):**
- `SELECT * FROM KORLEVEL`
- `SELECT * FROM ZALOGLEVEL`
- `WHERE SORSZAM=`
- `DELETE FROM IKTATO`
- `INSERT INTO IKTATO (DATUM,SORSZAM,TARTALOM,IKTATOSZAM,FILENEV)`
- `UPDATE PARAMETERS SET LASTSORSZAM=`
- `SELECT * FROM PARAMETERS`
- `SELECT * FROM IKTATO`
- `UPDATE PARAMETERS SET SOFFICEPATH=`
- `SELECT * FROM SIGNAL`
- `WHERE (DOLGSORSZAM=`
- `INSERT INTO SIGNAL (DOLGSORSZAM,LETTERNUM,MIKOR)`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
