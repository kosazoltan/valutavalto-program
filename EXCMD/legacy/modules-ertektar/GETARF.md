# Legacy modul (ÉRTÉKTÁR): GETARF

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/getarf/debug/unit2.pas` (9143 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/getarf/makedll/getarf.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`arfolyamletoltes`

## DFM form(ok) / képernyő
`TForm1`, `TGETARFOLYAM`

**Feliratok/gombok (Caption):** Form1 · Button1 · Button2 · GETARFOLYAM · ELSZ · Rendben

## Eljárások / függvények (.pas)
`AlapAdatBeolvasas`, `FormActivate`, `InditoTimerTimer`, `AktCurrateTorlese`, `FTPszerverbeBelep`, `ibParancs`, `Intdekodol`, `TGETARFOLYAM.FormActivate`, `TGetarfolyam.alapadatbeolvasas`, `TGetArfolyam.InditoTimerTimer`, `TGetarfolyam.Intdekodol`, `TGetarfolyam.FTPszerverbeBelep`, `Tgetarfolyam.ibParancs`, `TGetarfolyam.AktcurrateTorlese`

## Érintett adatbázis-táblák
`ARFOLYAM`, `HARDWARE`

**SQL-műveletek (minta):**
- `SELECT* FROM HARDWARE`
- `UPDATE ARFOLYAM SET ELSZAMOLASIARFOLYAM=`
- `WHERE VALUTANEM=`
- `UPDATE ARFOLYAM SET ELSZAMOLASIARFOLYAM=100`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
