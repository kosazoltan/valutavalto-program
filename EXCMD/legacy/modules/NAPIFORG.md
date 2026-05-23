# Legacy modul: NAPIFORG

> Forrás (primer): `Anti/VALUTA/DLL/NAPIFORG/MAKEDLL/Unit2.pas` (20654 karakter) · library: `DLL/NAPIFORG/MAKEDLL/Napiforg.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`napiforgalomrutin`

## DFM form(ok) / képernyő
`TNAPIFORGALOMFORM`

**Feliratok/gombok (Caption):** NAPIFORGALOMFORM · A NAPI FORGALOM KIMUTAT · VISSZA · VALUTA · NYIT · ELAD · NYOMTAT

## Eljárások / függvények (.pas)
`ESCAPEGOMBClick`, `FormActivate`, `NapiForgalomJob`, `Nyomtatas`, `NYOMTATOGOMBClick`, `GetHaviNyitok`, `GetHaviForgalom`, `GetNapiNyitok`, `GetNapiforgalom`, `HzarBeiras`, `Zaroszamitas`, `ValutaParancs`, `AlapadatBeolvasas`, `Blokkfocimiro`, `TextKiiro`, `KozepreIr`, `Scandnem`, `Elokieg`, `Nulele`, `FormKiir`, `ForintForm`, `TNAPIFORGALOMFORM.FormActivate`, `TnapiForgalomForm.Scandnem`, `TNapiForgalomForm.NapiForgalomJob`, `TNAPIFORGALOMFORM.NYOMTATOGOMBClick`, `TNAPIFORGALOMFORM.ESCAPEGOMBClick`, `TNAPIFORGALOMFORM.GetHavinyitok`, `TNapiForgalomForm.GetHaviforgalom`, `TNapiForgalomForm.Getnapinyitok`, `TNapiForgalomForm.GetNapiforgalom`

## Érintett adatbázis-táblák
`BLOKKTETEL`, `HARDWARE`, `HAVIZAR`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `WHERE (DATUM<`
- `WHERE (DATUM=`
- `SELECT * FROM BLOKKTETEL`
- `DELETE FROM HAVIZAR`
- `INSERT INTO HAVIZAR (VALUTANEM,NYITO,VETEL,ELADAS,ATVETEL,ATADAS,ZARO)`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
