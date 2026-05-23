# Legacy modul: SENDOKMANY

> Forrás (primer): `Anti/VALUTA/DLL/SENDOKMANY/MAKEDLL/Unit2.pas` (10995 karakter) · library: `DLL/SENDOKMANY/MAKEDLL/SENDOKMANY.DPR`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`sendokmanyrutin`

## DFM form(ok) / képernyő
`TForm2`

**Feliratok/gombok (Caption):** Form2 · OKM

## Eljárások / függvények (.pas)
`FormActivate`, `KILEPOTimer`, `ParaBeolvasas`, `GetRemoteAddress`, `Getdir`, `VoltezazUgyfel`, `Getjpgends`, `TForm2.FormActivate`, `TForm2.Getjpgends`, `TForm2.KILEPOTimer`, `TForm2.Parabeolvasas`, `TForm2.VoltezazUgyfel`, `TForm2.Getdir`, `TForm2.GetRemoteAddress`

## Érintett adatbázis-táblák
`BF`, `HARDWARE`, `JOGI`, `VTEMP`

**SQL-műveletek (minta):**
- `SELECT * FROM BF`
- `WHERE ((UGYFELTIPUS=`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM VTEMP`
- `SELECT * FROM JOGI WHERE SORSZAM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
