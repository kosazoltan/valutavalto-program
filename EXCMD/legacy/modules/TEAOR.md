# Legacy modul: TEAOR

> Forrás (primer): `Anti/VALUTA/DLL/TEAOR/MAKEDLL/Unit2.pas` (4973 karakter) · library: `DLL/TEAOR/MAKEDLL/teaorsel.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`teaorvalasztas`

## DFM form(ok) / képernyő
`TForm2`

**Feliratok/gombok (Caption):** Form2 · KERES · TEAOR NEGNEVEZ

## Eljárások / függvények (.pas)
`FormActivate`, `TEAORRACSKeyDown`, `BitBtn1Click`, `TEAORRACSDblClick`, `Betuvalto`, `TForm2.FormActivate`, `TForm2.TEAORRACSKeyDown`, `TForm2.BitBtn1Click`, `TForm2.TEAORRACSDblClick`, `TForm2.Betuvalto`

## Érintett adatbázis-táblák
`TEAORTABLA`

**SQL-műveletek (minta):**
- `SELECT * FROM TEAORTABLA ORDER BY TEAOR`
- `SELECT * FROM TEAORTABLA ORDER BY TEAORNEV`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
