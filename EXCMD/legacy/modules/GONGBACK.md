# Legacy modul: GONGBACK

> Forrás (primer): `Anti/VALUTA/DLL/GONGBACK/MAKEDLL/Unit2.pas` (5242 karakter) · library: `DLL/GONGBACK/MAKEDLL/GongBack.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`gongyvisszavonas`

## DFM form(ok) / képernyő
`TForm2`

**Feliratok/gombok (Caption):** Form2 · A G

## Eljárások / függvények (.pas)
`Button1Click`, `FormActivate`, `KilepoTimer`, `RemoteParancs`, `TForm2.Button1Click`, `TForm2.FormActivate`, `TForm2.KILEPOTimer`, `TForm2.RemoteParancs`

## Érintett adatbázis-táblák
`HARDWARE`, `VTEMP`

**SQL-műveletek (minta):**
- `SELECT * FROM VTEMP`
- `SELECT * FROM HARDWARE`
- `DELETE FROM`
- `WHERE BIZONYLATSZAM=`
- `SELECT * FROM`
- `WHERE SORSZAM=`
- `UPDATE`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
