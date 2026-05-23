# Legacy modul (ÉRTÉKTÁR): PILLKESZ

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/pillkesz/debug/unit2.pas` (62654 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/pillkesz/makedll/pillkesz.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`pillanatnyikeszlet`

## DFM form(ok) / képernyő
`TForm1`, `TPILLKESZFORM`, `THAVITABLO`

**Feliratok/gombok (Caption):** Form1 · Button1 · Button2 · Pillanatnyi k · Kil · Adatfrissit · 150 · GBP · RUB · AUD · BAM · CAD · BRL · BGN · CHF · FORGALOM · 254 000 · 2 580 · 150 660 · 150 000 · ILS · 1 949 · MXN · RON · NZD

## Eljárások / függvények (.pas)
`AdatFrissites`, `AdatFrissitoGomClick`, `Adatnullazo`, `AdatokTombbeOlvasasa`, `AdatTablaClear`, `AdatTablaDisplay`, `AdatSummazo`, `EgyirodaDisplay`, `FileEvolution`, `FormActivate`, `FormCreate`, `FTPSzerverbeBelep`, `GethardwareAdatok`, `InditoTimerTimer`, `KeszletDownLoad`, `KilepesGombClick`, `KilepoTimerTimer`, `OsszesTablaDisplay`, `PenztarTablaClear`, `PenztarTablaDisplay`, `PenztarTablaSzinezo`, `PTAR1PANELClick`, `Ptar0PanelEnter`, `PTAR1PANELMouseMove`, `PtOsszesenPanelEnter`, `PtOsszesenPanelClick`, `PtOsszesenPanelExit`, `Summanullazo`, `FtForm`, `HunDatetostr`

## Érintett adatbázis-táblák
`ARFOLYAM`, `HARDWARE`, `IRODAK`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM IRODAK`
- `WHERE (CLOSED<>`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM ARFOLYAM WHERE VALUTANEM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NEM TALÁLOM AZ IRODAK.DAT FILE-T
- Nem tlálom a WININET.DLL libraryt
- Hibás 

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
