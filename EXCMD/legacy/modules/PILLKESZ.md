# Legacy modul: PILLKESZ

> Forrás (primer): `Anti/VALUTA/DLL/PILLKESZ/MAKEDLL/Unit2.pas` (63283 karakter) · library: `DLL/PILLKESZ/MAKEDLL/PILLKESZ.DPR`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`pillanatnyikeszlet`

## DFM form(ok) / képernyő
`TForm1`, `THAVITABLO`, `TPILLKESZFORM`

**Feliratok/gombok (Caption):** Form1 · Button1 · Button2 · HAVITABLO · ELAD · NAPI V · NAPI ELAD · NAPI FORGALOM · VISSZA · Pillanatnyi k · Kil · Adatfrissit · 150 · GBP · RUB · AUD · BAM · CAD · BRL · BGN · CHF · FORGALOM · 254 000 · 2 580 · 150 660

## Eljárások / függvények (.pas)
`AdatFrissites`, `AdatFrissitoGomClick`, `Adatnullazo`, `AdatokTombbeOlvasasa`, `AdatTablaClear`, `AdatTablaDisplay`, `AdatSummazo`, `EgyirodaDisplay`, `FileEvolution`, `FormActivate`, `FormCreate`, `FTPSzerverbeBelep`, `GethardwareAdatok`, `InditoTimerTimer`, `KeszletDownLoad`, `KilepesGombClick`, `KilepoTimerTimer`, `OsszesTablaDisplay`, `PenztarTablaClear`, `PenztarTablaDisplay`, `PenztarTablaSzinezo`, `PTAR1PANELClick`, `Ptar0PanelEnter`, `PTAR1PANELMouseMove`, `PtOsszesenPanelEnter`, `PtOsszesenPanelClick`, `PtOsszesenPanelExit`, `Summanullazo`, `FtForm`, `HunDatetostr`

## Érintett adatbázis-táblák
`ARFOLYAM`, `HARDWARE`, `IRODAK`

**SQL-műveletek (minta):**
- `SELECT * FROM IRODAK`
- `WHERE (CLOSED<>`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM ARFOLYAM WHERE VALUTANEM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NEM TALÁLOM AZ IRODAK.DAT FILE-T
- Nem tlálom a WININET.DLL libraryt
- Hibás 

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
