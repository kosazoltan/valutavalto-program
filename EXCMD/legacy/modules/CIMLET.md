# Legacy modul: CIMLET

> Forrás (primer): `Anti/VALUTA/DLL/CIMLET/MAKEDLL/Unit2.pas` (32190 karakter) · library: `DLL/CIMLET/MAKEDLL/Cimlet.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`cimletezorutin`

## DFM form(ok) / képernyő
`TCIMLETEZES`

**Feliratok/gombok (Caption):** CIMLETEZES · 154 235 658 · 250 500 000 · 98 500 000 ·  7 500 · 1 000 · 14 250 · 99 000 · 6 000 · 16 580 · 12 000 · 6 320 ·  2 540 · 64 000 · 123 330 · 585 626 000 · 20 000 - es: · 10 000 - es: · 5 000 - es: · 2 000 - es: · 1 000 - es: · 500 - as: · 200 - as: · 100 - as: · 50 - es:

## Eljárások / függvények (.pas)
`CimletbeMasolas`, `Cimskip`, `ConfigInstall`, `Ed1Enter`, `Ed1Exit`, `Ed1KeyDown`, `ExitGombClick`, `FormActivate`, `FormCreate`, `IbParancs`, `KilepoTimerTimer`, `Kimasol`, `NN1Click`, `NN1MouseMove`, `Nullazo`, `QuitGombClick`, `RrSummazas`, `SaveCimini`, `Shape16MouseMove`, `UjDevizatValasztott`, `ValutanevPanelTorles`, `F4`, `Ftform`, `Scandnem`, `supervisorjelszo`, `TCimletezes.FormCreate`, `TCIMLETEZES.FormActivate`, `TCimletezes.F4`, `Tcimletezes.Nullazo`, `TCIMLETEZES.NN1MouseMove`

## Érintett adatbázis-táblák
`CIMINI`, `CIMLETEK`, `HARDWARE`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `UPDATE CIMINI SET CIMLETEZETT=0,READY=0,CIMLET1=0,CIMLET2=0,`
- `WHERE CIMLETTYPE=`
- `UPDATE CIMINI SET CIMLETEZETT=`
- `WHERE (CIMLETTYPE=`
- `SELECT * FROM CIMINI`
- `DELETE FROM CIMLETEK`
- `WHERE (CIMLETTYPE=1) AND (AKTKESZLET>0)`
- `INSERT INTO CIMLETEK (DATUM,VALUTANEM,VALUTANEV,OSSZESFORINTERTEK,`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NINCS MIT CÍMLETEZNI
- HIBÁS A CIMINI FILE

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
