# Legacy modul: MAIFORG

> Forrás (primer): `Anti/VALUTA/DLL/MAIFORG/MAKEDLL/Unit2.pas` (11330 karakter) · library: `DLL/MAIFORG/MAKEDLL/Maiforg.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`maiforgalomrutin`

## DFM form(ok) / képernyő
`TMAIFORGALOMTABLAFORM`

**Feliratok/gombok (Caption):** MAIFORGALOMTABLAFORM · VISSZA · A MAI NAPI FORGALOM  · ELAD · VALUTA · FORINT · VALUTANEM · 123.456.789 Ft · FT  · MIND · ***

## Eljárások / függvények (.pas)
`FormActivate`, `AlapadatBeolvasas`, `Scandnem`, `AdatGyujtes`, `Adatfeliras`, `ValutaParancs`, `AdatKijelzes`, `Ftform`, `ESCAPEGOMBClick`, `TMAIFORGALOMTABLAFORM.FormActivate`, `TmaiForgalomTablaForm.Adatgyujtes`, `TmaiForgalomTablaForm.Scandnem`, `TmaiForgalomTablaForm.AlapadatBeolvasas`, `TmaiForgalomTablaForm.Adatfeliras`, `TmaiForgalomTablaForm.ValutaParancs`, `TmaiForgalomTablaForm.AdatKijelzes`, `TmaiForgalomTablaForm.Ftform`, `TMAIFORGALOMTABLAFORM.ESCAPEGOMBClick`

## Érintett adatbázis-táblák
`BLOKKFEJ`, `BLOKKTETEL`, `HARDWARE`, `NAPIZAR`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM BLOKKFEJ`
- `WHERE (STORNO=1) AND (DATUM=`
- `SELECT * FROM BLOKKTETEL`
- `SELECT * FROM`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `DELETE FROM NAPIZAR`
- `INSERT INTO NAPIZAR (VALUTANEV,VETEL,VETELFORINT,ELADAS,ELADASFORINT)`
- `SELECT* FROM NAPIZAR`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
