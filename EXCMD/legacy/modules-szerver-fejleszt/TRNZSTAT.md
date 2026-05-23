# Legacy modul (SZERVER-FEJLESZT): TRNZSTAT

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/trnzstat/unit1.pas` (6052 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/trnzstat/project1.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · START · 2011 · 12 · 125

## Eljárások / függvények (.pas)
`BitBtn1Click`, `Nulele`, `Ezertektar`, `TForm1.BitBtn1Click`, `TForm1.Nulele`, `TForm1.Ezertektar`

## Érintett adatbázis-táblák
`TRANZAKCIOK`

**SQL-műveletek (minta):**
- `DELETE FROM TRANZAKCIOK`
- `SELECT * FROM`
- `WHERE (STORNO=1) AND ((TIPUS=`
- `INSERT INTO TRANZAKCIOK (EV,HONAP,PENZTAR,VASARLO,ELADO,KONVERTALO)`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
