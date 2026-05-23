# Legacy modul: NZNYOMT

> Forrás (primer): `Anti/VALUTA/DLL/NZNYOMT/MAKEDLL/Unit2.pas` (52172 karakter) · library: `DLL/NZNYOMT/MAKEDLL/NzNyomt.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`napzarnyomtatorutin`

## DFM form(ok) / képernyő
`TNAPZARNYOMTATOFORM`

**Feliratok/gombok (Caption):** NAPZARNYOMTATOFORM · NAPI Z

## Eljárások / függvények (.pas)
`Adatgyujtes`, `ArfolyamLista`, `BlokkFocimIro`, `DnemBeolvasas`, `FoglaloKeszletNyomtatas`, `FormActivate`, `KunaNyomtatas`, `IdozitoTimer`, `Kezelesidijnyomtatas`, `KozepreIr`, `NapiForgalomLista`, `NapZaroKeszletek`, `NzForgalom`, `NzPenztarAtadVesz`, `PenztarAllas`, `StartNyomtatas`, `TradezaroLista`, `VonalHuzo`, `WuWaDataRead`, `WuWaLista`, `VAlutaParancs`, `ArfolyamForm`, `DnemScan`, `Elokieg`, `F6`, `F9`, `ForintForm`, `FormKiir`, `Kieg`, `S9`

## Érintett adatbázis-táblák
`ARFOLYAM`, `FOGLALOKESZLET`, `HARDWARE`, `HAVIZAR`, `HRKNAPLO`, `NAPIKEZELESIDIJ`, `NAPIOSSZESITO`, `PARAMETERS`, `PENZTAR`, `VTEMP`

**SQL-műveletek (minta):**
- `SELECT * FROM VTEMP`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `UPDATE VTEMP SET OTVENEDIK=0`
- `SELECT * FROM`
- `WHERE DATUM=`
- `SELECT * FROM NAPIKEZELESIDIJ`
- `WHERE (DATUM=`
- `SELECT * FROM FOGLALOKESZLET`
- `SELECT * FROM PARAMETERS`
- `SELECT * FROM NAPIOSSZESITO`
- `SELECT * FROM HAVIZAR`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
