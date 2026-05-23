# Legacy modul: MENTES

> Forrás (primer): `Anti/VALUTA/DLL/MENTES/MAKEDLL/Unit2.pas` (3970 karakter) · library: `DLL/MENTES/MAKEDLL/MENTES.DPR`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`backuprestore`

## DFM form(ok) / képernyő
`TNAPIMENTES`

**Feliratok/gombok (Caption):** NAPI ADATMENT

## Eljárások / függvények (.pas)
`ValutaFdbMentes`, `FormActivate`, `KilepoTimer`, `ValutaParancs`, `Nulele`, `TNAPIMENTES.FormActivate`, `TNapiMentes.ValutaParancs`, `TNAPIMENTES.KILEPOTimer`, `TnapiMentes.ValutaFdbMentes`, `TNapiMentes.Nulele`

## Érintett adatbázis-táblák
`VTEMP`

**SQL-műveletek (minta):**
- `DELETE FROM VTEMP`
- `INSERT INTO VTEMP (DATUM,NEVTABLA)`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
