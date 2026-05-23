# Legacy modul (ÉRTÉKTÁR): PTARKESZ

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/ptarkesz/debug/unit2.pas` (5730 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/ptarkesz/makedll/aktkesz.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`penztarikeszletek`

## DFM form(ok) / képernyő
`TForm1`, `TPTARKESZ`

**Feliratok/gombok (Caption):** Form1 · Button1 · KIL · PTARKESZ · Az  · Forint k · Valut · Western Union · USD · HUF · Elektromos keresked · TELJES P · VISSZA · Kezel

## Eljárások / függvények (.pas)
`VisszaGombClick`, `FormActivate`, `TablaTorles`, `Adatbeolvasas`, `Adatkijelzes`, `Start`, `FtForm`, `TPTARKESZ.VisszaGombClick`, `TPTARKESZ.FormActivate`, `TPtarkesz.Start`, `TPtarKesz.TablaTorles`, `TPtarkesz.Adatbeolvasas`, `TPtarkesz.Adatkijelzes`, `TPTarkesz.FtForm`

## Érintett adatbázis-táblák
`ARFOLYAM`, `EKERDATA`, `KEZDIJDATA`, `WUAFAADATOK`

**SQL-műveletek (minta):**
- `SELECT * FROM ARFOLYAM WHERE ZARO>0`
- `SELECT * FROM WUAFAADATOK`
- `SELECT * FROM KEZDIJDATA`
- `SELECT * FROM EKERDATA`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
