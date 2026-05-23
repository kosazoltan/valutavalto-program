# Legacy modul (SZERVER-FEJLESZT): BESZAM

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/beszam/unit3.pas` (64836 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/beszam/makebesz.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`, `TMAKEEXCEL`, `TADATGYUJTES`

**Feliratok/gombok (Caption):** Form1 · dek@nySoft · 12 · 10 · 11 · KIL · HAVI BESZ · MELYIK H · MAKEEXCEL · Excelt · 2015 SZEPTEMBER HAVI BESZ

## Eljárások / függvények (.pas)
`FormActivate`, `Settombok`, `AllCounty`, `Tombtotomb`, `FillPolygon`, `Megyevillantas`, `KorzetAdatLetoltes`, `Forgalomlegyujtes`, `Wulegyujtes`, `Haszonletoltes`, `TranzadoLegyujtes`, `MakeBeszTabla`, `BeszParancs`, `AkthaviAdatFeliras`, `ElozoeviAdatLoad`, `TombbolAktvari`, `AdatNullazas`, `INDITOTimer`, `Polygon_GetBounds`, `Polygon_PtInside`, `Polygon_GetFillRange`, `TADATGYUJTES.FormActivate`, `TADATGYUJTES.Allcounty`, `TADATGYUJTES.tombtotomb`, `TADATGYUJTES.Settombok`, `TADATGYUJTES.FillPolygon`, `AddIntersection`, `TADATGYUJTES.INDITOTimer`, `TAdatGyujtes.KorzetAdatLetoltes`, `TAdatgyujtes.Forgalomlegyujtes`

## Érintett adatbázis-táblák
`TOP`, `TRANZDIJ`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `WHERE (STORNO=1) AND ((TIPUS=`
- `WHERE (BIZONYLATSZAM=`
- `WHERE (STORNO=1) AND (UGYFELTIPUS=`
- `SELECT * FROM TRANZDIJ`
- `UPDATE`
- `WHERE PENZTAR=`
- `INSERT INTO`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
