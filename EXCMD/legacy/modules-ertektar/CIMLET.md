# Legacy modul (ÉRTÉKTÁR): CIMLET

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/cimlet/debug/unit2.pas` (32721 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/cimlet/makedll/cimlet.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`cimletezorutin`

## DFM form(ok) / képernyő
`TForm1`, `TCIMLETEZES`

**Feliratok/gombok (Caption):** Form1 · Button1 · BitBtn1 · Panel1 · CIMLETEZES · 154 235 658 · 250 500 000 · 98 500 000 ·  7 500 · 1 000 · 14 250 · 99 000 · 6 000 · 16 580 · 12 000 · 6 320 ·  2 540 · 64 000 · 123 330 · 585 626 000 · 20 000 - es: · 10 000 - es: · 5 000 - es: · 2 000 - es: · 1 000 - es:

## Eljárások / függvények (.pas)
`CimletbeMasolas`, `Cimskip`, `ConfigInstall`, `Ed1Enter`, `Ed1Exit`, `Ed1KeyDown`, `ExitGombClick`, `FormActivate`, `FormCreate`, `IbParancs`, `KilepoTimerTimer`, `Kimasol`, `NN1Click`, `NN1MouseMove`, `Nullazo`, `QuitGombClick`, `RrSummazas`, `SaveCimini`, `Shape16MouseMove`, `UjDevizatValasztott`, `ValutanevPanelTorles`, `F4`, `Ftform`, `Gyomlal`, `Scandnem`, `supervisorjelszo`, `TCimletezes.FormCreate`, `TCIMLETEZES.FormActivate`, `TCimletezes.F4`, `Tcimletezes.Nullazo`

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
- `INSERT INTO CIMLETEK (DATUM,VALUTANEM,BANKJEGY,`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NINCS MIT CÍMLETEZNI
- HIBÁS A CIMINI FILE

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
