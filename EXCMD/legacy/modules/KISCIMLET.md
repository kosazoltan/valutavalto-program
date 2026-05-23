# Legacy modul: KISCIMLET

> Forrás (primer): `Anti/VALUTA/DLL/KISCIMLET/MAKEDLL/Unit2.pas` (26491 karakter) · library: `DLL/KISCIMLET/MAKEDLL/Kiscim.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`kiscimletezes`

## DFM form(ok) / képernyő
`TKISCIMLET`

**Feliratok/gombok (Caption):** USD · 20 000 · 223 456 999 · 10 000 · S2PANEL · 2 000 · S4PANEL · 500 · S6PANEL · S13PANEL · 1 000 · S5PANEL · 5 000 · S3PANEL · 100 · S8PANEL · 200 · S7PANEL · 20 · S10PANEL · 10 · S11PANEL · 50 · S9PANEL · S12PANEL

## Eljárások / függvények (.pas)
`Adatrogzites`, `Aktival`, `BitBtn2Click`, `CfgBedolgozas`, `CimletKeszGombClick`, `CimletVegGombClick`, `DezAktival`, `DNam1Click`, `Flag1Click`, `FormActivate`, `MegsemGombClick`, `p1Exit`, `e1EditEnter`, `e1EditKeyUp`, `e1EditExit`, `KilepoTimer`, `Menustart`, `Munka`, `p1Enter`, `Summazas`, `TablaUrites`, `ValutatValasztott`, `Wordbeiro`, `ZaroByteIro`, `Ele4`, `FtForm`, `ScanTenyDnem`, `ScanDnem`, `FormCreate`, `TKiscimlet.FormActivate`

## Érintett adatbázis-táblák
`VTEMP`

**SQL-műveletek (minta):**
- `SELECT * FROM VTEMP`
- `WHERE BANKJEGY>0`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
