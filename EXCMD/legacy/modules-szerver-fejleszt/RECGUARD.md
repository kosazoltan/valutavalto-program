# Legacy modul (SZERVER-FEJLESZT): RECGUARD

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/recguard/unit1.pas` (15862 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/recguard/recguard.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1

## Eljárások / függvények (.pas)
`CiklusTimer`, `FormActivate`, `GarbageCollection`, `Futascontrol`, `GepujraInditas`, `GetDatumIdo`, `ReceptorLeallitas`, `Logbair`, `RunReceptor`, `CsomagClear`, `ReceptParancs`, `GetCamDatum`, `Percszamito`, `WindowsExit`, `TForm1.FormActivate`, `TForm1.CIKLUSTimer`, `TForm1.RunReceptor`, `TForm1.GarbageCollection`, `TForm1.GetCamDatum`, `TForm1.GepUjraInditas`, `TForm1.Getdatumido`, `TForm1.Logbair`, `TForm1.Percszamito`, `TForm1.Futascontrol`, `TForm1.ReceptorLeallitas`, `TForm1.ReceptParancs`, `TForm1.Csomagclear`

## Érintett adatbázis-táblák
`RENDSZER`

**SQL-műveletek (minta):**
- `SELECT * FROM RENDSZER`
- `UPDATE RENDSZER SET CAMCLEAR=`
- `UPDATE RENDSZER SET CSOMAGNEV=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
