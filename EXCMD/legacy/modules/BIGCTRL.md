# Legacy modul: BIGCTRL

> Forrás (primer): `Anti/VALUTA/DLL/BIGCTRL/MAKEDLL/Unit2.pas` (44249 karakter) · library: `DLL/BIGCTRL/MAKEDLL/Bigctrl.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`gongyoletcontrol`

## DFM form(ok) / képernyő
`TForm2`

**Feliratok/gombok (Caption):** Form2 · AZ 

## Eljárások / függvények (.pas)
`FormActivate`, `AlapadatBeolvasas`, `Bizonylatregisztralo`, `GetNaturDataFromRemote`, `GetJogiDatafromRemote`, `JogiAdatBeolvasas`, `KilepTimer`, `Konyveles`, `NaturAdatBeolvasas`, `RemoteParancs`, `UpdateMBValtozoadatok`, `UpdateNaturValtozoadatok`, `ValutaParancs`, `VtempNullazas`, `Angolra`, `DoubleKill`, `FtForm`, `HutoGb`, `Napidiff`, `Nulele`, `String2Date`, `Tomorito`, `WithoutIrszam`, `WithoutLetter`, `supervisorjelszo`, `getengedelyrutin`, `TForm2.FormActivate`, `TForm2.NaturAdatBeolvasas`, `TForm2.GetNaturDataFromRemote`, `TForm2.JogiAdatBeolvasas`

## Érintett adatbázis-táblák
`HARDWARE`, `JOGI`, `JOGISZEMELY`, `LASTNUMS`, `UGYFEL`, `VTEMP`

**SQL-műveletek (minta):**
- `UPDATE JOGI SET MBDATASORSZAM=`
- `WHERE SORSZAM=`
- `SELECT * FROM UGYFEL WHERE UGYFELSZAM=`
- `SELECT * FROM`
- `WHERE NEV=`
- `SELECT * FROM JOGISZEMELY WHERE UGYFELSZAM=`
- `SELECT * FROM JOGI`
- `WHERE JOGISZEMELYNEV LIKE`
- `UPDATE JOGI SET TEAOR=`
- `SELECT * FROM LASTNUMS`
- `UPDATE LASTNUMS SET`
- `INSERT INTO`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NINCS ÜGYFÉLSZÁM
- A SZERVER NEM ÉRHETŐ EL !
- AZ ÜGYFÉL LE VAN TILTVA !
- AZ ÜGYFÉL CSAK FORRÁS MEGJELÖLÉSSEL VÁLTHAT !
- A JOGISZEMÉLY LE VAN TILTVA !
- AZ ÜGYFÉL CSAK FORRÁSMEGJELÖLÉSSEL VÁLTHAT !

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
