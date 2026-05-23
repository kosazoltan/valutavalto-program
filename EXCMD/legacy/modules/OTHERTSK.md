# Legacy modul: OTHERTSK

> Forrás (primer): `Anti/VALUTA/DLL/OTHERTSK/MAKEDLL/Unit2.pas` (40614 karakter) · library: `DLL/OTHERTSK/MAKEDLL/Othertsk.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`othertaskrutin`

## DFM form(ok) / képernyő
`TEGYEBBEALLITASFORM`

**Feliratok/gombok (Caption):** EGYEBBEALLITASFORM · AZ  · KERESEM: · ANYJA NEVE · SZ · LAKCIME · OKM · VISSZA · EGY · VALUT · KIL · NAPNYIT · NAPZ · ADATLAPOK KEZEL · OTP POS TERMIN · OTP-TERMIN · VISSZA A MEN · A TERMIN · PARAM · 3. sz · 2.1.  Kapcsolod · 1.1  Gyanus  · 1.2.  Az  · 1.4.  Kijel · 3.1.  Az 

## Eljárások / függvények (.pas)
`FormActivate`, `Menube`, `BEALLITASGOMBClick`, `BACKTOMENUGOMBClick`, `ALLVALUTACLEARGOMBClick`, `ALLVALUTAINSTALLGOMBClick`, `ValutaParancs`, `kilepoTimer`, `PTARGEPGOMBClick`, `ADATLAPGOMBClick`, `UGYTMKGOMBClick`, `BejelentMain`, `Aposztless`, `WriteMelleklet8`, `Mellek1Print`, `NAPZARASGOMBClick`, `NORMNYITASGOMBClick`, `NYITAS3GOMBClick`, `NAPNYITASGOMBClick`, `ADATRACSEnter`, `ADATRACSExit`, `KORULMENY8EDITEnter`, `KORULMENY8EDITExit`, `NEVEDITKeyDown`, `KORULMENY8EDITKeyDown`, `Adatmentes`, `EXITGOMBClick`, `FtForm`, `LastTranzRead`, `Kozepreir`

## Érintett adatbázis-táblák
`ADATLAP`, `BEJELENT`, `GONGYCSOMAG`, `HARDWARE`, `JOGISZEMELY`, `PENZTAR`, `QRPARAMS`, `UGYFEL`, `VTEMP`

**SQL-műveletek (minta):**
- `SELECT * FROM BEJELENT WHERE SORSZAM=`
- `SELECT * FROM ADATLAP WHERE SORSZAM=`
- `SELECT * FROM GONGYCSOMAG WHERE GONGYCSOMAGSZAM=`
- `SELECT * FROM JOGISZEMELY WHERE UGYFELSZAM=`
- `SELECT * FROM UGYFEL WHERE UGYFELSZAM=`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM GONGYCSOMAG WHERE UGYFELSZAM=`
- `UPDATE BEJELENT SET LEIRAS=`
- `WHERE SORSZAM=`
- `INSERT INTO BEJELENT (SORSZAM,LEIRAS,`
- `DELETE FROM QRPARAMS`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NEM TALÁLOM A KÉRT ADATLAPOT !
- NINCSENEK ADATAIM A KÉRT JELENTÉSHEZ !

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
