# Legacy modul: ESTIZAR

> Forrás (primer): `Anti/VALUTA/DLL/ESTIZAR/MAKEDLL/Unit2.pas` (89959 karakter) · library: `DLL/ESTIZAR/MAKEDLL/Estizar.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`estizaraskuldes`

## DFM form(ok) / képernyő
`TMAKEPACK`

**Feliratok/gombok (Caption):** Egy napi z · NAPI Z · MELYIK NAP Z · << el · CSOMAGOL · 2012 szeptember · Csomag felir

## Eljárások / függvények (.pas)
`CsomagoloGombClick`, `BFPack`, `BTPack`, `CimtPack`, `NarfPack`, `WafaPack`, `WuniPack`, `TescPack`, `ArfePack`, `XkezPack`, `WzarPack`, `Tulajbedolgozas`, `EfejPack`, `EtetPack`, `TradePack`, `FoglaloPack`, `ElohoGombClick`, `ValutaParancs`, `FormActivate`, `HonapDisplay`, `KovhoGombClick`, `MatricaKodolas`, `Ugyfelpack`, `UTombBeir`, `MegsemZarGombClick`, `PutByte`, `Putword`, `PutInteger`, `Putstring`, `Putchar`

## Érintett adatbázis-táblák
`FOGLALOKESZLET`, `HARDWARE`, `MEDIA`, `NAPIOSSZESITO`, `PENZTAR`, `UGYFEL`, `UJTULAJOK`

**SQL-műveletek (minta):**
- `SELECT * FROM PENZTAR`
- `SELECT * FROM HARDWARE`
- `UPDATE HARDWARE SET LEZARTNAP=`
- `SELECT * FROM`
- `WHERE DATUM=`
- `SELECT * FROM FOGLALOKESZLET`
- `SELECT * FROM NAPIOSSZESITO`
- `WHERE (DATUM=`
- `DELETE FROM MEDIA`
- `INSERT INTO MEDIA (LOCALPATH,REMOTEFILE,REMOTEDIR)`
- `SELECT * FROM UGYFEL WHERE UGYFELSZAM=`
- `UPDATE UGYFEL SET FELADVA=949 WHERE UGYFELSZAM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- A megjelölt nap a jövőben lesz !

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
