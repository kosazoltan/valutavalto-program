# Legacy modul (ÉRTÉKTÁR): NAPKONYV

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/napkonyv/debug/unit2.pas` (28692 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/napkonyv/makedll/napkonyv.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`napikonyvelorutin`

## DFM form(ok) / képernyő
`TForm1`, `TNAPIKONYV`

**Feliratok/gombok (Caption):** Form1 · Button1 · Button2 · Napi k · Vissza a f · El · 2013 · szeptember · 25 · cs

## Eljárások / függvények (.pas)
`Egyadatsor`, `EgynapiRekordInsert`, `ElohoGombClick`, `EvhonapDisplay`, `Fejlec`, `FormActivate`, `KilepoTimerTimer`, `KovHoGombClick`, `Kozepre`, `Lablec`, `NaploNapiPrintBejegyzes`, `NapiKonyvNyomtatas`, `NyomtatoGombClick`, `Szamtan`, `Ujoldaltnyit`, `ValutaParancs`, `VisszaGombClick`, `EloKieg`, `Form11`, `FtFormalo`, `GetNyito`, `Getvarosnev`, `GetZaro`, `Hundatetostr`, `Nulele`, `NulKieg`, `NAPTARChange`, `supervisorjelszo`, `TNapiKonyv.FormActivate`, `TNapiKonyv.EvhonapDisplay`

## Érintett adatbázis-táblák
`HARDWARE`, `NAPIKONYV`, `NAPLO`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM NAPIKONYV`
- `WHERE (DATUM<`
- `DELETE FROM NAPLO WHERE DATUM=`
- `INSERT INTO NAPLO (DATUM,STATUS)`
- `SELECT * FROM`
- `WHERE DATUM<`
- `WHERE VALUTANEM=`
- `WHERE DATUM=`
- `DELETE FROM NAPIKONYV WHERE DATUM=`
- `INSERT INTO NAPIKONYV (DATUM,KEZDOSORSZAM,VEGSORSZAM,BEDARAB,KIDARAB,`

## Felhasználói üzenetek (üzleti szabály-jelek)
- Hibas pénztárszám !

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
