# Legacy modul (SZERVER): WUAFATRANZ

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/wuafatranz/debug/unit2.pas` (30792 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/wuafatranz/makedll/wuwaadvet.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`wuafaatadatvet`

## DFM form(ok) / képernyő
`TForm1`, `TForm2`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · Form2 · AZ AFA  · DNEM · FOGADVA · FOGAD · ST · CSAK A NEMEGYEZ · AZ  · VISSZA A F · AFA VISSZAT · WESTERN UNION

## Eljárások / függvények (.pas)
`PenztarParaBeolvasas`, `PenztarSorEpito`, `GetIdoszak`, `KilepoTimer`, `FormActivate`, `ErtektarGyujto`, `PenztarGyujto`, `NoEquGombClick`, `AllTranzGombClick`, `BackToMenuGombClick`, `WafaGombClick`, `WuniGombClick`, `Wafafeliras`, `Wunifeliras`, `Wparancs`, `Nul3`, `Scanwafa`, `Scanwuni`, `Ezertektar`, `TForm2.FormActivate`, `TForm2.PenztarGyujto`, `TForm2.ERtektarGyujto`, `TForm2.Scanwafa`, `TForm2.Scanwuni`, `TForm2.PenztarSorEpito`, `TForm2.PenztarParaBeolvasas`, `TForm2.GetIdoszak`, `TForm2.KilepoTimer`, `TForm2.Ezertektar`, `TForm2.Nul3`

## Érintett adatbázis-táblák
`IDOSZAK`, `IRODAK`, `WAFATRANZ`, `WUNITRANZ`

**SQL-műveletek (minta):**
- `SELECT * FROM WAFATRANZ`
- `SELECT * FROM`
- `WHERE (DATUM>`
- `WHERE (DATUM>=`
- `SELECT * FROM IRODAK ORDER BY UZLET`
- `SELECT * FROM IDOSZAK`
- `DELETE FROM WAFATRANZ`
- `SELECT * FROM WAFATRANZ WHERE FOGADAS=`
- `UPDATE WAFATRANZ SET KULDES=`
- `WHERE FOGADAS=`
- `INSERT INTO WAFATRANZ (KULDES,KULDO,VALUTANEM,KULDOTTPENZ,`
- `SELECT * FROM WAFATRANZ WHERE KULDES=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
