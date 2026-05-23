# Legacy modul (SZERVER-FEJLESZT): TRANZDB

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/tranzdb/unit1.pas` (4784 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/tranzdb/project1.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · START · KILEP · ptarpanel

## Eljárások / függvények (.pas)
`Button2Click`, `Button1Click`, `UzletekBeolvasasa`, `Havikiolvasas`, `TForm1.Button2Click`, `TForm1.Button1Click`, `TForm1.UzletekBeolvasasa`, `TForm1.HaviKiolvasas`

## Érintett adatbázis-táblák
`BF1212`, `IRODAK`, `TRANZAKCIOK`

**SQL-műveletek (minta):**
- `SELECT * FROM IRODAK`
- `SELECT * FROM BF1212`
- `WHERE STORNO=1`
- `INSERT INTO TRANZAKCIOK (PENZTAR,CEGBETU,VETEL,ELADAS,KONVERZIO,`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
