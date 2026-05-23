# Legacy modul: FIRSTCTRL

> Forrás (primer): `Anti/VALUTA/DLL/FIRSTCTRL/MAKEDLL/Unit2.pas` (7077 karakter) · library: `DLL/FIRSTCTRL/MAKEDLL/FirstCtrl.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`firstcontrol`

## DFM form(ok) / képernyő
`TForm2`

**Feliratok/gombok (Caption):** Form2 · A K · A valutav · MEGSZ · A kezel · A Western Union p · AFA visszat · Foglal · TOV · IGEN · NEM

## Eljárások / függvények (.pas)
`FormActivate`, `AlapAdatBeolvasas`, `vvIgenClick`, `GombAllitas`, `Flagcontrol`, `GombokTombbe`, `TovabbGOMBClick`, `vvNemClick`, `vParancs`, `TForm2.FormActivate`, `TForm2.Alapadatbeolvasas`, `TForm2.GombAllitas`, `TForm2.VVIGENClick`, `TForm2.Flagcontrol`, `TForm2.GombokTombbe`, `TForm2.TOVABBGOMBClick`, `TForm2.VVNEMClick`, `TForm2.vParancs`

## Érintett adatbázis-táblák
`FOGLALOKESZLET`, `HARDWARE`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM FOGLALOKESZLET`
- `UPDATE HARDWARE SET MENETSZAM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
