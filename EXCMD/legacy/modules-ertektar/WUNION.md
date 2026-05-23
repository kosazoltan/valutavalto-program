# Legacy modul (ÉRTÉKTÁR): WUNION

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/wunion/makedll/unit2.pas` (38811 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/wunion/makedll/wunion.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`westernunionrutin`

## DFM form(ok) / képernyő
`TForm1`, `TForm2`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · Form2 · WESTERN UNION  · WESTERN UNION-OS P · AFA-S P · AFAS P · BIZONYLATOK MEGTEKINT · VISSZAT · WESTERN UNION K · AFAS K · 132 456 000 USD · 123 456 789 HUF · 254 000 000 Ft · WESTERN UNION P · ASEDFRGTZXDFGHBHGFDXDRFGTHZUJXDFGTHZUJXX · TRANZAKCI · KIADOTT BIZONYLATOK LIST · VNEM · EL · VISSZA A MEN · BIZONYLAT STORN · BIZONYLAT NAPJ · 2014.12.31

## Eljárások / függvények (.pas)
`AFAAtvetGombClick`, `AFAAtadGombClick`, `AlapadatBeolvasas`, `BankjegyBevitel`, `BizBackGombClick`, `BizonylatDisplay`, `BizonylatGombClick`, `BizonylatNyomtatas`, `DnemComboChange`, `ElohoGombClick`, `FormActivate`, `KeszletBeolvasas`, `KeszletDisplay`, `Kinyomtatas`, `KodEditEnter`, `KodEditExit`, `KodEditKeyDown`, `KovhoGombClick`, `Kozostranzakcio`, `Mainapdisplay`, `MasikDatumGombClick`, `Menube`, `NaptarChange`, `NaptarDblClick`, `PartnerValasztoGombClick`, `PenzEditKeyDown`, `PenztarOkeGOMBClick`, `PenztarRacsDblClick`, `PenztarRacsKeyDown`, `PenztartValasztott`

## Érintett adatbázis-táblák
`HARDWARE`, `PENZTAR`, `VTEMP`, `WPENZSZALLITAS`, `WUAFAADATOK`, `WUAFAFORG`, `WUNI`

**SQL-műveletek (minta):**
- `SELECT * FROM PENZTAR`
- `WHERE PENZTARKOD<>`
- `INSERT INTO PENZTAR (PENZTARKOD,PENZTARNEV,PENZTARCIM,TELEFONSZAM)`
- `UPDATE VTEMP SET PENZTARKOD=`
- `SELECT * FROM WUAFAADATOK`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM WUNI`
- `WHERE DATUM=`
- `INSERT INTO WUAFAFORG (DATUM,VALUTANEM,BIZONYLAT,BANKJEGY,ELOJEL,`
- `INSERT INTO WPENZSZALLITAS (DATUM,BIZONYLATSZAM,SZALLITONEV,`
- `UPDATE WUAFAADATOK SET`
- `DELETE FROM VTEMP`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
