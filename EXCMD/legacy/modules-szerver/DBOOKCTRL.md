# Legacy modul (SZERVER): DBOOKCTRL

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/dbookctrl/debug/unit2.pas` (16149 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/dbookctrl/makedll/dbctrl.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`daybookcontrol`

## DFM form(ok) / képernyő
`TForm1`, `TDBOOKCTRL`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · DBOOKCTRL · DAYBOOK ADATB

## Eljárások / függvények (.pas)
`ChParancs`, `ZParancs`, `FormActivate`, `KilepoTimer`, `MakeExpDayBook`, `MakeEngedely`, `MakePterm`, `MakeChDaybook`, `PenztarBeolvasas`, `SetChDaybook`, `SetZDayBook`, `Nulele`, `TDBOOKCTRL.FormActivate`, `TDBookCtrl.SetchDayBook`, `TDBookCtrl.SetZDayBook`, `TDBookCtrl.MakeChDaybook`, `TDBOOKCTRL.MakeExpDayBook`, `TDBOOKCTRL.ChParancs`, `TDBOOKCTRL.ZParancs`, `TDBookCtrl.PenztarBeolvasas`, `TDBOOKCTRL.MakeEngedely`, `TDbookctrl.MakePterm`, `TDBOOKCTRL.KILEPOTimer`, `TdBookCtrl.Nulele`

## Érintett adatbázis-táblák
`IRODAK`

**SQL-műveletek (minta):**
- `UPDATE`
- `WHERE PENZTAR=`
- `INSERT INTO`
- `SELECT * FROM IRODAK`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
