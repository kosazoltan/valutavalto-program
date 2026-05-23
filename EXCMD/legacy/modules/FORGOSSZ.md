# Legacy modul: FORGOSSZ

> Forrás (primer): `Anti/VALUTA/DLL/FORGOSSZ/MAKEDLL/Unit2.pas` (15135 karakter) · library: `DLL/FORGOSSZ/MAKEDLL/Forgossz.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`forgosszrutin`

## DFM form(ok) / képernyő
`TVALUTAOSSZESITOFORM`

**Feliratok/gombok (Caption):** VALUTAOSSZESITOFORM · TELJES FORGALOM  · ID · -T · -IG · 2007.11.22 · 2007.11.25

## Eljárások / függvények (.pas)
`ForgalomOsszesito`, `Nullazas`, `TextKiiro`, `KozepreIr`, `FormActivate`, `AlapadatBeolvasas`, `Ftform`, `GetKertdatumAdatok`, `KILEPOTimer`, `Scandnem`, `TVALUTAOSSZESITOFORM.FormActivate`, `TVALUTAOSSZESITOFORM.AlapadatBeolvasas`, `TVALUTAOSSZESITOFORM.FORGALOMOSSZESITO`, `TValutaOsszesitoForm.Scandnem`, `TVALUTAOSSZESITOFORM.KozepreIr`, `TValutaOsszesitoForm.Ftform`, `TValutaOsszesitoForm.GetKertdatumAdatok`, `TVALUTAOSSZESITOFORM.KILEPOTimer`, `TVALUTAOSSZESITOFORM.Nullazas`, `TVALUTAOSSZESITOFORM.TextKiiro`

## Érintett adatbázis-táblák
`HARDWARE`, `IDOSZAK`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `SELECT FEJ.*,TET.*`
- `FROM`
- `WHERE (FEJ.DATUM>=`
- `SELECT * FROM IDOSZAK`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NINCS ADAT A KÉRT HÓNAPRÓL
- NINCS ADAT A KÉRT IDŐSZAKRÓL

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
