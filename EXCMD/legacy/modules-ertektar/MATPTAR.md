# Legacy modul (ÉRTÉKTÁR): MATPTAR

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/matptar/debug/unit2.pas` (21274 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/matptar/makedll/matptar.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`matpenztarrutin`

## DFM form(ok) / képernyő
`TForm1`, `TMATPENZTAR`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · MATPENZTAR · ELEKTROMOS-KERESKED · E-KERESKEDELMI P · E-KERESKEDELEM  PILLANATNYI K · BIZONYLATOK MEGTEKINT · VISSZA A F · BIZONYLATSZ · Ft · TRB · B-123456 · TRANZAKCI · KIBIZPANEL · PILLANATNYI K · 12 550 000 Ft · VISSZA · ELEKTROMOS KERESKED · EL

## Eljárások / függvények (.pas)
`AlapAdatBeolvasas`, `BizonylatPrint`, `Konyveles`, `BeMegsemGombClick`, `BeOkeGombClick`, `BeOsszegEditEnter`, `BeOsszegEditExit`, `BeOsszegEditKeyDown`, `BevetGombClick`, `BizonylatGombClick`, `BizVisszaGombClick`, `FormActivate`, `KeszletGombClick`, `KiadGombClick`, `KiMegsemGombClick`, `KiOkeGombClick`, `KiOsszegEditKeyDown`, `EkerDataBeolvas`, `MatricaGombClick`, `PillVisszaGombClick`, `PlombaAdatBeolvasas`, `Ptarbeolvasas`, `RePrintGombClick`, `ReturnGombClick`, `ValutaParancs`, `ForintForm`, `Nul6`, `Nulele`, `blokknyomtatas`, `TMATPENZTAR.FormActivate`

## Érintett adatbázis-táblák
`EKERDATA`, `EKERESKEDELEM`, `HARDWARE`, `PENZTAR`, `UTOLSOBLOKKOK`, `VTEMP`, `WPENZSZALLITAS`

**SQL-műveletek (minta):**
- `SELECT * FROM EKERDATA`
- `SELECT * FROM UTOLSOBLOKKOK`
- `SELECT * FROM VTEMP`
- `INSERT INTO EKERESKEDELEM (DATUM,BIZONYLAT,ELOJEL,BANKJEGY,`
- `UPDATE UTOLSOBLOKKOK SET LASTEKER=`
- `INSERT INTO WPENZSZALLITAS (DATUM,BIZONYLATSZAM,PLOMBASZAM,`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM WPENZSZALLITAS WHERE BIZONYLATSZAM=`
- `DELETE FROM VTEMP`
- `INSERT INTO VTEMP (TIPUS,DATUM,BIZONYLATSZAM,ELOJEL,PENZTARKOD,`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
