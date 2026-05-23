# Legacy modul: PROSKI

> Forrás (primer): `Anti/VALUTA/DLL/PROSKI/MAKEDLL/Unit2.pas` (2475 karakter) · library: `DLL/PROSKI/MAKEDLL/Proski.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`penztaroskileptetes`

## DFM form(ok) / képernyő
`TPROSKILEP`

**Feliratok/gombok (Caption):** PROSKILEP

## Eljárások / függvények (.pas)
`FormActivate`, `kilepotimerTimer`, `Valutaparancs`, `TPROSKILEP.FormActivate`, `TPROSKILEP.kilepotimerTimer`, `Tproskilep.Valutaparancs`

## Érintett adatbázis-táblák
`HARDWARE`, `JELENLET`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `UPDATE HARDWARE SET IDKOD=`
- `UPDATE JELENLET SET KILEPES=`
- `WHERE(IDKOD=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
