# Legacy modul (SZERVER-FEJLESZT): RECPTOR

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/recptor/orecept/unit1.pas` (107548 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/recptor/wrecept.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`, `TTABMAKER`, `TGETLETTER`, `TKESZLETREGISZT`, `TMENTES`, `TPERSONALBEDOLGOZAS`, `TSTORNOBIZONYLATOK`, `TBIGSUM`

**Feliratok/gombok (Caption):** BE · KIL · SEG · VISSZA A NORM · NAPI FORGALOM  · TABL · MENT · Verz:  5.00 · Button1 · Button2 · TABMAKER · Form1 · GETLETTER · Havi tabl · HAVI  KEDVEZM · MEHET · KESZLETIRO · 2009 szeptember 21 cs · TELJES K · UZENOPANEL · LETILTVA · MENTES · ADATMENT · SIKERTELEN · PERSONALBEDOLGOZAS

## Eljárások / függvények (.pas)
`ClearDirectory`, `ColorKor`, `Datumkijelzes`, `DayRegister`, `Dirempty`, `EgytablaDekoder`, `EmailElkuldes`, `FigyeloTimer`, `FormActivate`, `GetIrodaAdatok`, `KeszletRegisztralas`, `KilepoGombClick`, `KilepoIdozitoTimer`, `KorClear`, `KortombBetolto`, `MakeArfe`, `MakeBf`, `MakeBt`, `MakeCimtar`, `MakeDayBook`, `MakeGDBFile`, `MakeIbTabla`, `MakeNarf`, `MakeTesc`, `MakeTrade`, `MakeWafa`, `MakeWuni`, `MakeWZar`, `MarkSundays`, `MFileDetected`

## Érintett adatbázis-táblák
`CIMT`, `DAILYMAIL`, `EMAIL`, `IRODAK`, `RENDSZER`, `WZAR`

**SQL-műveletek (minta):**
- `DELETE FROM`
- `WHERE DATUM=`
- `SELECT * FROM IRODAK`
- `SELECT * FROM`
- `SELECT * FROM RENDSZER`
- `UPDATE RENDSZER SET MUNKANAP=`
- `INSERT INTO`
- `UPDATE`
- `WHERE PENZTAR=`
- `UPDATE RENDSZER SET UTMENTES=`
- `SELECT * FROM CIMT`
- `SELECT * FROM WZAR`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
