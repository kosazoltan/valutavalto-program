# Legacy modul (ÉRTÉKTÁR): BLOKNYOM

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/bloknyom/debug/unit2.pas` (32739 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/bloknyom/makedll/bloknyom.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`blokknyomtatas`

## DFM form(ok) / képernyő
`TForm1`, `TBLOKKNYOM`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · BLOKKNYOM · Nyomtat

## Eljárások / függvények (.pas)
`FormActivate`, `GetVtempBasic`, `GetPenztarData`, `CimletNyomtatas`, `AtadBlokkNyomtatas`, `AtveszBlokkNyomtatas`, `StornoBlokknyomtatas`, `WuAfaNyomtatas`, `EkerNyomtatas`, `KezdijNyomtatas`, `WUKeszletNyomtatas`, `WuAfaStornoBlokk`, `BlokkFocimIro`, `BlokkFejlecIro`, `BlokkTetelIro`, `VonalHuzo`, `KozepreIr`, `TextKiiro`, `KilepotimerTimer`, `Soremeles`, `startNyomtatas`, `FtForm`, `Elokieg`, `HunDateTostr`, `ForintForm`, `ArfolyamForm`, `Nulele`, `blokknyomtatas`, `TBLOKKNYOM.FormActivate`, `TBlokknyom.GetVtempBasic`

## Érintett adatbázis-táblák
`HARDWARE`, `PENZTAR`, `VTEMP`, `WUAFAADATOK`

**SQL-műveletek (minta):**
- `SELECT * FROM VTEMP`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM HARDWARE`
- `WHERE (BANKJEGY>0)`
- `SELECT * FROM WUAFAADATOK`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
