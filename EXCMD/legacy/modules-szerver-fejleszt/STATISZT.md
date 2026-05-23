# Legacy modul (SZERVER-FEJLESZT): STATISZT

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/statiszt/unit1.pas` (10812 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/statiszt/project1.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · Button1 · Button2 · Panel1

## Eljárások / függvények (.pas)
`Button2Click`, `Button1Click`, `Ugyfelazonositas`, `Adatregisztralas`, `Nullazo`, `FormActivate`, `DbUrites`, `TForm1.Button2Click`, `TForm1.Button1Click`, `TForm1.Ugyfelazonositas`, `TForm1.Adatregisztralas`, `TForm1.Nullazo`, `TForm1.FormActivate`

## Érintett adatbázis-táblák
`BF1710`, `BT1710`, `DATA1710`, `IRODAK`, `JOGISZEMELY`, `UGYFEL`

**SQL-műveletek (minta):**
- `SELECT * FROM BF1710`
- `WHERE (STORNO=1) and (FIZETENDO>=300000)`
- `SELECT FEJ.*, TET.*`
- `FROM BF1710 FEJ JOIN BT1710 TET`
- `WHERE (FEJ.STORNO=1) AND (OSSZESEN>=300000)`
- `SELECT * FROM UGYFEL`
- `WHERE UGYFELSZAM=`
- `SELECT * FROM JOGISZEMELY`
- `INSERT INTO DATA1710 (NEV,PENZTAR,CEGBETU,DATUM,VALNEM1,BANKJEGY1,`
- `DELETE FROM DATA1710`
- `SELECT * FROM IRODAK`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
