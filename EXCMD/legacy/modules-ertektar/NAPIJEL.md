# Legacy modul (ÉRTÉKTÁR): NAPIJEL

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/napijel/debug/unit2.pas` (43159 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/napijel/makedll/napijel.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`napijelrutin`

## DFM form(ok) / képernyő
`TForm1`, `TNAPIJELENTES`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · KEZEL · 257 426 000 Ft · E-KERESKEDELEM · 345 000 000 Ft · NYOMTAT · Pillanatnyi p · DNEM · ELAD · 20 000 · 4 500 · 10 000 · 100 · 112 · 1 200 · 50 · 5 000 · 2 000 · 1 000 · 500 · 200 · 20 · 10

## Eljárások / függvények (.pas)
`FormActivate`, `DataLapClear`, `DataLapDisplay`, `MemoKerekEnter`, `MemoKerekExit`, `AlapAdatBeolvasas`, `EgyjelentesOlvasas`, `Kivilagositas`, `Kiszinezes`, `EgyirodaJelentese`, `PagesAppear`, `ValutaParancs`, `TombBeToltes`, `KilepoTimerTimer`, `CancelGombClick`, `JelentesExit`, `JelszoEditKeyDown`, `NyomtatasGombClick`, `VisszaGombClick`, `MinuszGombClick`, `PluszGombClick`, `DatumOkeGombClick`, `PillParancs`, `SetValutanem`, `MasikIrodaGombClick`, `ArfForm`, `DataKibonto`, `FtForm`, `SetjelentesPath`, `Nulele`

## Érintett adatbázis-táblák
`ARFOLYAM`, `HARDWARE`, `MEDIA`, `NAPIZAR`, `PENZTAR`, `VTEMP`

**SQL-műveletek (minta):**
- `DELETE FROM VTEMP`
- `INSERT INTO VTEMP (DATUM) VALUES (`
- `SELECT * FROM MEDIA`
- `SELECT * FROM ARFOLYAM`
- `WHERE VALUTANEM=`
- `DELETE FROM NAPIZAR`
- `INSERT INTO NAPIZAR (VALUTANEM,VETEL,ELADAS,ZARO)`
- `SELECT * FROM NAPIZAR`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`

## Felhasználói üzenetek (üzleti szabály-jelek)
- AZ INFORMÁCIÓS FILE HIBÁS ! NEM LEHET ÉRTELMEZNI !
- A MEGADOTT JELSZÓ NEM MEGFELELŐ !

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
