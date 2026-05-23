# Legacy modul: PTARKESZ

> Forrás (primer): `Anti/VALUTA/DLL/PTARKESZ/MAKEDLL/Unit2.pas` (6882 karakter) · library: `DLL/PTARKESZ/MAKEDLL/AKTKESZ.DPR`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`penztarikeszletek`

## DFM form(ok) / képernyő
`TPTARKESZ`

**Feliratok/gombok (Caption):** PTARKESZ · Forint k · Valut · WESTERN UNION · USD · HUF · ELEKTROMOS KERESKEDELEM · TELJES P · VISSZA · Kezel · FOGLAL

## Eljárások / függvények (.pas)
`VisszaGombClick`, `FormActivate`, `TablaTorles`, `Adatbeolvasas`, `Adatkijelzes`, `ibnyitas`, `FtForm`, `regeneralorutin`, `TPTARKESZ.VisszaGombClick`, `TPTARKESZ.FormActivate`, `TPtarKesz.TablaTorles`, `TPtarkesz.Adatbeolvasas`, `TPtarkesz.ibnyitas`, `TPtarkesz.Adatkijelzes`, `TPTarkesz.FtForm`

## Érintett adatbázis-táblák
`ARFOLYAM`, `FOGLALOKESZLET`, `KEZELESIDATA`, `PARAMETERS`, `WUAFAADATOK`

**SQL-műveletek (minta):**
- `SELECT * FROM WUAFAADATOK`
- `SELECT * FROM KEZELESIDATA`
- `SELECT * FROM FOGLALOKESZLET`
- `SELECT * FROM ARFOLYAM`
- `SELECT * FROM PARAMETERS`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
