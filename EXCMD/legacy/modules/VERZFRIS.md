# Legacy modul: VERZFRIS

> Forrás (primer): `Anti/VALUTA/DLL/VERZFRIS/MAKEDLL/Unit2.pas` (33272 karakter) · library: `DLL/VERZFRIS/MAKEDLL/verzfris.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`verziofrissitorutin`

## DFM form(ok) / képernyő
`TForm1`, `TVFRISS`

**Feliratok/gombok (Caption):** Form1 · START · KIL · VERZIOFRISSITOFORM · Verzi

## Eljárások / függvények (.pas)
`FormActivate`, `KILEPOTimer`, `AlapadatBeolvasas`, `ValutaParancs`, `Frissitoidobekuldes`, `NavSorszamBeiro`, `SettingNavCOm`, `KijelzoCsere`, `Foglalorendezes`, `TradeModosito`, `IkonKirako`, `TranzdijChange`, `ServerreLep`, `WinExecAndWait32`, `WindowsExit`, `TVFriss.FormActivate`, `TVFRISS.AlapadatBeolvasas`, `TVfriss.SettingNavcom`, `TVfriss.KijelzoCsere`, `TVFriss.ServerreLep`, `TVFRISS.Frissitoidobekuldes`, `TVFriss.ValutaParancs`, `TVfriss.WinExecAndWait32`, `TVFRISS.KILEPOTimer`, `TVFRISS.Navsorszambeiro`, `TVFriss.SetRegiSvajcifrank`, `TVfriss.FoglaloRendezes`, `TVfriss.TranzdijChange`, `TVfriss.TradeModosito`, `TVFriss.IkonKirako`

## Érintett adatbázis-táblák
`ARFOLYAM`, `CIKKTORZS`, `FOGLALOK`, `FRISSITESEK`, `HARDWARE`, `JOGISZEMELY`, `PARAMETERS`, `PENZTAR`, `RDB`, `TRANZDIJTABLA`

**SQL-műveletek (minta):**
- `UPDATE HARDWARE SET VERZIO=`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `UPDATE HARDWARE SET NAVCOM=1`
- `UPDATE FRISSITESEK SET`
- `WHERE VERZIO=`
- `UPDATE ARFOLYAM SET NAVSORSZAM=`
- `WHERE VALUTANEM=`
- `SELECT * FROM FOGLALOK WHERE HIVATKOZAS=`
- `DELETE FROM TRANZDIJTABLA`
- `INSERT INTO TRANZDIJTABLA (TRANZAKCIO,KEZELESIDIJ,SORSZAM)`
- `UPDATE HARDWARE SET KEZDIJMAX=9990`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
