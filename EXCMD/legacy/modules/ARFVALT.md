# Legacy modul: ARFVALT

> Forrás (primer): `Anti/VALUTA/DLL/ARFVALT/MAKEDLL/Unit2.pas` (7746 karakter) · library: `DLL/ARFVALT/MAKEDLL/Arfvalt.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`arfvaltrutin`

## DFM form(ok) / képernyő
`TARFOLYAMVALTOZTATAS`

**Feliratok/gombok (Caption):** Eredeti  · Kedvezm · KANADAI DOLL · 25500 · KEDVEZM · 1,98 %) · (Kedvezm · ENGED

## Eljárások / függvények (.pas)
`FormActivate`, `ArfModiOkeGombClick`, `ArfModiCancelGombClick`, `EngedelyGombClick`, `UjArfolyamEditEnter`, `UjArfolyamEditExit`, `UjArfolyamEditKeyDown`, `supervisorjelszo`, `arfvaltrutin`, `TARFOLYAMVALTOZTATAS.FormActivate`, `TARFOLYAMVALTOZTATAS.UJARFOLYAMEDITKeyDown`, `TARFOLYAMVALTOZTATAS.UJARFOLYAMEDITEnter`, `TARFOLYAMVALTOZTATAS.UJARFOLYAMEDITExit`, `TarfolyamValtoztatas.ArfModiCancelGombClick`, `TARFOLYAMVALTOZTATAS.ENGEDELYGOMBClick`, `TArfolyamValtoztatas.ArfModiOkeGombClick`

## Érintett adatbázis-táblák
`VTEMP`

**SQL-műveletek (minta):**
- `SELECT * FROM VTEMP WHERE VALUTANEM=`
- `UPDATE VTEMP SET KEDVEZMENYESARFOLYAM=`
- `WHERE VALUTANEM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- A kedvezény meghaladja a 2 %-ot. Igy újabb jelszó szükséges

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
