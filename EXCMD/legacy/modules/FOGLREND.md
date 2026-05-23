# Legacy modul: FOGLREND

> Forrás (primer): `Anti/VALUTA/DLL/FOGLREND/MAKEDLL/Unit3.pas` (20325 karakter) · library: `DLL/FOGLREND/MAKEDLL/foglrend.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`foglalorendeles`

## DFM form(ok) / képernyő
`TRENDELOFORM`

**Feliratok/gombok (Caption):** RENDELOFORM · VALUTA FOGLAL · Megrendelt valuta neme: · A megrendelt valuta mennyis · Kialkudott  · A megrendel · Az  · RENDEL · MILYEN TRANZAKCI · ELAD

## Eljárások / függvények (.pas)
`Arfolyambetoltes`, `ArfolyamEditKeyDown`, `ArfolyamBedolgozas`, `BankjegyBedolgozas`, `BJegyEditEnter`, `BJegyEditExit`, `BJegyEditKeyDown`, `DnemComboChange`, `EladasGombClick`, `FParancs`, `FormActivate`, `FDnemComboChange`, `FoglaloEditKeyDown`, `FoglaloBedolgozas`, `HidoEditKeyDown`, `HidoEditEnter`, `HidoBedolgozas`, `MegsemGombClick`, `RendbenGombClick`, `StartProgram`, `VetelGombClick`, `Vegszamitas`, `Diffmake`, `Ftform`, `Kerekito`, `Nulele`, `ARFOLYAMEDITExit`, `FOGLALOEDITExit`, `HIDOEDITExit`, `ARFOLYAMEDITEnter`

## Érintett adatbázis-táblák
`ARFOLYAM`, `VTEMP`

**SQL-műveletek (minta):**
- `DELETE FROM VTEMP`
- `INSERT INTO VTEMP (TIPUS)`
- `UPDATE VTEMP SET VALUTANEM=`
- `SELECT * FROM ARFOLYAM`
- `WHERE (VALUTANEM<>`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
