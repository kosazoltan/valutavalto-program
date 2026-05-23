# Legacy modul (SZERVER-FEJLESZT): EVITRANZ

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/evitranz/unit1.pas` (4125 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/evitranz/project2.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · BEST · EAST · PANNON · BitBtn1 · BitBtn2 · penztar · honap

## Eljárások / függvények (.pas)
`IrodaBeolvasas`, `BitBtn2Click`, `BitBtn1Click`, `Nulele`, `Ezertektar`, `TForm1.BitBtn2Click`, `TForm1.BitBtn1Click`, `TForm1.irodaBeolvasas`, `TForm1.Nulele`, `Tform1.Ezertektar`

## Érintett adatbázis-táblák
`IRODAK`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `WHERE (STORNO=1) AND (TIPUS=`
- `Select * FROM IRODAK`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
