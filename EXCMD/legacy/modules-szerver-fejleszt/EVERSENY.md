# Legacy modul (SZERVER-FEJLESZT): EVERSENY

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/everseny/unit1.pas` (38104 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/everseny/acversny.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** EXPRESSZ Z · dekanySoft · KIL · FORGALOM SZ

## Eljárások / függvények (.pas)
`BitBtn2Click`, `STARTGOMBClick`, `FormActivate`, `PTarbeolvasas`, `PtarosBeolvasas`, `HaviBlokkRead`, `HaviWuniRead`, `adatFeliras`, `VersenyParancs`, `MakeExcel`, `TablaRajzolas`, `ExcelKill`, `AdatFeltoltes`, `QuitGombClick`, `HelyezesIras`, `VastagKeret`, `VekonyKeret`, `Angolra`, `Nulele`, `HutoGb`, `Idcontrol`, `scanidkod`, `RealToStr`, `Ketdec`, `EVCOMBOChange`, `TForm1.FormActivate`, `TForm1.STARTGOMBClick`, `TForm1.Nulele`, `TForm1.PtarBeolvasas`, `TForm1.PtarosBeolvasas`

## Érintett adatbázis-táblák
`IRODAK`, `PENZTAR`, `PENZTAROS`, `PENZTAROSOK`

**SQL-műveletek (minta):**
- `SELECT * FROM IRODAK`
- `WHERE (CLOSED=`
- `SELECT * FROM PENZTAROSOK`
- `SELECT * FROM`
- `WHERE ((TIPUS=`
- `WHERE (FOEGYSEG=5) AND (STORNO=1)`
- `WHERE VALUTANEM=`
- `DELETE FROM PENZTAR`
- `DELETE FROM PENZTAROS`
- `INSERT INTO PENZTAR (PENZTARSZAM,PENZTARNEV,EHAVIFORGALOM,`
- `INSERT INTO PENZTAROS (IDKOD,PENZTAROSNEV,ELOZOHAVIFORGALOM,`
- `SELECT * FROM PENZTAR`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
