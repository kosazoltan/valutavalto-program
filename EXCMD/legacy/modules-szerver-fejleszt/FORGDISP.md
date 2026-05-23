# Legacy modul (SZERVER-FEJLESZT): FORGDISP

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/forgdisp/unit1.pas` (5662 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/forgdisp/project1.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · BitBtn1 · Panel1 · START

## Eljárások / függvények (.pas)
`BitBtn1Click`, `Gyparancs`, `PenztarAdatOLvasas`, `EgynapFeldolgozas`, `MakePenztarsor`, `Legyujtes`, `BitBtn2Click`, `TForm1.BitBtn1Click`, `TForm1.BitBtn2Click`, `TForm1.Egynapfeldolgozas`, `TForm1.MakePenztarsor`, `TForm1.Legyujtes`, `TForm1.Gyparancs`

## Érintett adatbázis-táblák
`FORG2DAYS`, `IRODAK`

**SQL-műveletek (minta):**
- `DELETE FROM FORG2DAYS`
- `SELECT FEJ.*, TET.*`
- `FROM`
- `WHERE (FEJ.STORNO=1) AND ((FEJ.TIPUS=`
- `SELECT * FROM`
- `SELECT * FROM IRODAK`
- `INSERT INTO FORG2DAYS (PENZTARSZAM,PENZTARNEV,DATUM,IDO,`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
