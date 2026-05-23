# Legacy modul (ÉRTÉKTÁR): REGEN

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/regen/debug/unit2.pas` (26856 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/regen/makedll/regen.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`regeneralorutin`

## DFM form(ok) / képernyő
`TForm1`, `TREGENERALO`

**Feliratok/gombok (Caption):** Form1 · Button1 · Button2 · A PILLANATNYI  · KEZEL · E-KERESKEDELEM-AFAK · REGENER

## Eljárások / függvények (.pas)
`FormActivate`, `IdozitoTimer`, `AdatNullazas`, `NyitoBetoltes`, `KeszletRegeneralo`, `KeszletRogzites`, `HaviForgalomBedolgozas`, `NapiForgalomBedolgozas`, `WuAfaRegeneralo`, `HaviWuforgGyujto`, `NapiWuforgGyujto`, `WuAfaForgalom`, `WuAfaRogzites`, `Kezdijregeneralo`, `KezdijRogzites`, `EkerRegeneralo`, `EkerRogzites`, `ValutaParancs`, `GetHardwareData`, `Nulele`, `Dnemscan`, `TREGENERALO.FormActivate`, `TRegeneralo.IdozitoTimer`, `TRegeneralo.KeszletRegeneralo`, `TRegeneralo.HaviForgalomBedolgozas`, `TRegeneralo.NapiForgalomBedolgozas`, `TRegeneralo.Keszletrogzites`, `TRegeneralo.WuAfaRegeneralo`, `TRegeneralo.WuAfaForgalom`, `TRegeneralo.haviWuforgGyujto`

## Érintett adatbázis-táblák
`ARFOLYAM`, `BLOKKTETEL`, `EKERDATA`, `EKERESKEDELEM`, `HARDWARE`, `KEZDIJ`, `KEZDIJDATA`, `WUAFAADATOK`, `WUAFAFORG`, `WZARO`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `WHERE STORNO=1`
- `SELECT * FROM BLOKKTETEL`
- `UPDATE ARFOLYAM`
- `WHERE VALUTANEM=`
- `SELECT * FROM WUAFAFORG WHERE STORNO=1`
- `UPDATE WUAFAADATOK SET USDKESZLET=`
- `DELETE FROM WZARO`
- `INSERT INTO WZARO (DATUM,USDNYITO,HUFNYITO,AFANYITO,USDBEVETEL,`
- `SELECT * FROM KEZDIJ`
- `DELETE FROM KEZDIJDATA`
- `INSERT INTO KEZDIJDATA (DATUM,NYITO,BEVETEL,KIADAS,ZARO)`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
