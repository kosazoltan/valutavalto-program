# Legacy modul: TESCO

> Forrás (primer): `Anti/VALUTA/DLL/TESCO/MAKEDLL/Unit2.pas` (53980 karakter) · library: `DLL/TESCO/MAKEDLL/Tesco.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`tescorutin`

## DFM form(ok) / képernyő
`TTESCOFORM`

**Feliratok/gombok (Caption):** 01 · BIZONYLATOK  · KIL · FORINT: · BIZONYLATSZ · TRANZAKCI · INNOVA INVEST-T · B-123456 · 245,256,000 · AFAVISSZAT · BIZONYLAT SZ · SZ · 5 %-OS  · 27 %-OS  · KIFIZETEND · Ft · 18 %-OS  · V-345880 · 123.456.780 Ft · RENDBEN · MEGJEGYZ · KIADOTT  TESCOS   · BIZONYLAT · PARTNERN · STORN

## Eljárások / függvények (.pas)
`AdveszBlokk`, `AfavisszaBlokk`, `Attekintes`, `BizBeolvaso`, `BizlistVegeGombClick`, `CancelGombClick`, `DataRacsKeyUp`, `DataracsCellClick`, `EscapeGombClick`, `EscGombClick`, `VonalHuzo`, `Fomenu`, `FormActivate`, `InnovaAtvetel`, `InnovaAtadas`, `PlombaWrite`, `GetKertdatumAdatok`, `BlokkFocimIro`, `KozosMunka`, `NyomtatoGombClick`, `GetWcegNev`, `PenzkeszletList`, `PenztarAtvetel`, `PenztarAtadas`, `Pillertek`, `RekordChange`, `RendbengombClick`, `StornoGombClick`, `StornoblokkNyom`, `GetWuKeszlet`

## Érintett adatbázis-táblák
`HARDWARE`, `IDOSZAK`, `PENZTAR`, `TESCO`, `VTEMP`, `WPENZSZALLITAS`, `WUAFAADATOK`, `WUAFACEGEK`, `WUGYFEL`

**SQL-műveletek (minta):**
- `INSERT INTO TESCO (DATUM,IDO,BIZONYLATTIPUS,BIZONYLATSZAM,WUGYFELSZAM,`
- `UPDATE WUAFAADATOK SET WAKTUALBIZONYLAT=`
- `SELECT * FROM WUGYFEL`
- `WHERE UGYFELSZAM=`
- `SELECT * FROM`
- `WHERE`
- `SELECT * FROM TESCO`
- `SELECT * FROM WUAFAADATOK`
- `SELECT * FROM IDOSZAK`
- `UPDATE`
- `WHERE BIZONYLATSZAM=`
- `INSERT INTO`

## Felhasználói üzenetek (üzleti szabály-jelek)
- HIÁNYZIK A KÉRT HAVI GYÜJTŐ
- NINCSENEK ADATAIM A KÉRT IDŐSZAKRÓL
- NINCS ENNYI 

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
