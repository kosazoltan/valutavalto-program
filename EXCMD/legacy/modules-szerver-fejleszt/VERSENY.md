# Legacy modul (SZERVER-FEJLESZT): VERSENY

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/verseny/unit1.pas` (23594 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/verseny/verseny.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`, `TJUTALEK`, `TMAKEEXCEL`, `TUJPENZTARFORGALOM`

**Feliratok/gombok (Caption):** Form1 · HAVI FORGALMI VERSENY SZ · Versenysz · JUTALEK · PROSNEVPANEL · VALTOPANEL · MAKEEXCEL · Excelt · KIL · UJPENZTARFORGALOM · honappanel

## Eljárások / függvények (.pas)
`FormActivate`, `ProsBeolvasas`, `PtarBeolvasas`, `JutfreeBizonylatok`, `ArfolyamBeolvasas`, `VersenyRogzites`, `VersenyParancs`, `SetpenztarSorrend`, `setProsSorrend`, `VersenyStart`, `getProsnev`, `EzErtektar`, `GetkonvOsszeg`, `Jutalekfree`, `Nulele`, `Getproskorzet`, `RealToStr`, `STARTGOMBClick`, `EVCOMBOChange`, `Panel1Click`, `Button1Click`, `HutoGb`, `Angolra`, `TForm1.FormActivate`, `TForm1.STARTGOMBClick`, `TForm1.VersenyStart`, `TForm1.VersenyRogzites`, `TForm1.Getproskorzet`, `TForm1.ProsBeolvasas`, `TForm1.PtarBeolvasas`

## Érintett adatbázis-táblák
`IRODAK`, `PENZTAR`, `PENZTAROS`, `PENZTAROSOK`

**SQL-műveletek (minta):**
- `DELETE FROM PENZTAR`
- `DELETE FROM PENZTAROS`
- `INSERT INTO PENZTAROS (IDKOD,PENZTAROSNEV,ELOZOHAVIFORGALOM,`
- `INSERT INTO PENZTAR (PENZTARSZAM,PENZTARNEV,ELOZOEVIFORGALOM,`
- `SELECT * FROM PENZTAROSOK`
- `SELECT * FROM IRODAK`
- `SELECT * FROM`
- `WHERE (BIZONYLATSZAM=`
- `WHERE ENGEDMENYTIPUS=34`
- `WHERE VALUTANEM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
