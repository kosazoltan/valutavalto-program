# Legacy modul (SZERVER-FEJLESZT): TRANZDIJ

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/tranzdij/unit1.pas` (5011 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/tranzdij/project1.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · PROGRAM INDUL · FAROKPANEL · PATHPANEL · uzenopanel

## Eljárások / függvények (.pas)
`Button1Click`, `FormActivate`, `TForm1.Button1Click`, `TForm1.FormActivate`

## Érintett adatbázis-táblák
`DAYB`, `TRANZDIJ`

**SQL-műveletek (minta):**
- `SELECT * FROM DAYB`
- `SELECT * FROM`
- `WHERE (STORNO=1) AND (DATUM>`
- `INSERT INTO TRANZDIJ (PENZTAR,VETEL,ELADAS,VFORG,EFORG)`
- `DELETE FROM TRANZDIJ`

## Felhasználói üzenetek (üzleti szabály-jelek)
- FELIRTAM !!!

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
