# Legacy modul (SZERVER-FEJLESZT): IDBEIRO

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/idbeiro/unit1.pas` (6921 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/idbeiro/project1.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`, `TSELECTPENZTAROS`

**Feliratok/gombok (Caption):** Form1 · PROGRAM INDUL · KIL · SELECTPENZTAROS · EZ A J

## Eljárások / függvények (.pas)
`BitBtn2Click`, `BitBtn1Click`, `PenztarBeolvasas`, `IbParancs`, `FormCreate`, `FormActivate`, `TForm1.BitBtn2Click`, `TForm1.BitBtn1Click`, `TForm1.PenztarBeolvasas`, `TForm1.IbParancs`, `TForm1.FormCreate`, `TForm1.FormActivate`

## Érintett adatbázis-táblák
`PENZTAROSOK`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `WHERE ((TIPUS=`
- `WHERE (UGYFELTIPUS=`
- `UPDATE`
- `WHERE PENZTAROSNEV=`
- `WHERE IDKOD=`
- `SELECT * FROM PENZTAROSOK`

## Felhasználói üzenetek (üzleti szabály-jelek)
- A HÓNAP RENDBEN

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
