# Legacy modul (ÉRTÉKTÁR): NAPIKEZD

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/napikezd/debug/unit2.pas` (28985 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/napikezd/makedll/napikezd.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`napikezdijrutin`

## DFM form(ok) / képernyő
`TForm1`, `TNAPIKEZD`

**Feliratok/gombok (Caption):** Form1 · Button1 · Button2 · NYOMTAT · VISSZA A F · << EL · Dek

## Eljárások / függvények (.pas)
`Egyadatsor`, `ElohoGombClick`, `EvhonapDisplay`, `Fejlec`, `FormActivate`, `KilepoTimerTimer`, `Kozepre`, `KovHoGombClick`, `Lablec`, `NaploNapiPrintBejegyzes`, `KezdijNyomtatas`, `ValutaParancs`, `EgyNapiRekordInsert`, `NyomtatoGombClick`, `Ujoldaltnyit`, `VisszaGombClick`, `Szamtan`, `EloKieg`, `Form11`, `FtFormalo`, `HunDateTostr`, `KovetkezoNap`, `Nulele`, `NulKieg`, `PtarKepzo`, `NAPTARChange`, `Getnyito`, `GetZaro`, `supervisorjelszo`, `TNAPIKEZD.FormActivate`

## Érintett adatbázis-táblák
`HARDWARE`, `HZ`, `NAPIKEZD`, `NAPLO`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM NAPIKEZD`
- `WHERE (DATUM<`
- `SELECT * FROM`
- `WHERE DATUM<`
- `SELECT * FROM HZ`
- `WHERE DATUM=`
- `WHERE (DATUM=`
- `SELECT * FROM NAPLO`
- `INSERT INTO NAPLO (DATUM,STATUS)`
- `UPDATE NAPLO SET STATUS=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- Hibas pénztárszám !
- Hibás pénztárszám !

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
