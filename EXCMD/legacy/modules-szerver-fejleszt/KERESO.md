# Legacy modul (SZERVER-FEJLESZT): KERESO

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/kereso/unit1.pas` (5464 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/kereso/project2.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · KERES · KIL

## Eljárások / függvények (.pas)
`BitBtn2Click`, `ExParancs`, `BitBtn1Click`, `TForm1.BitBtn2Click`, `TForm1.BitBtn1Click`, `TForm1.ExParancs`

## Érintett adatbázis-táblák
`KERES`

**SQL-műveletek (minta):**
- `DELETE FROM KERES`
- `SELECT FEJ.*,TET.*`
- `FROM`
- `WHERE (FEJ.STORNO=1) AND (FEJ.BIZONYLATSZAM LIKE`
- `SELECT * FROM`
- `WHERE SORSZAM=`
- `INSERT INTO KERES (DATUM,IDO,BIZONYLATSZAM,BANKJEGY,`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
