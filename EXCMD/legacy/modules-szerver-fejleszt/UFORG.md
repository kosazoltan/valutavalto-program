# Legacy modul (SZERVER-FEJLESZT): UFORG

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/uforg/unit1.pas` (7031 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/uforg/project1.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · Button1 · FAROKPANEL · PATHPANEL · uzenopanel

## Eljárások / függvények (.pas)
`Button1Click`, `FormActivate`, `getsorszam`, `TForm1.Button1Click`, `TForm1.getsorszam`, `TForm1.FormActivate`

## Érintett adatbázis-táblák
`DAYB`, `UGYFELFORGALOM`

**SQL-műveletek (minta):**
- `SELECT * FROM DAYB`
- `SELECT * FROM`
- `WHERE STORNO=1`
- `INSERT INTO UGYFELFORGALOM (EVHOS,V1,E1,V2,E2,V3,E3,V4,E4,V5,E5,`
- `DELETE FROM UGYFELFORGALOM`

## Felhasználói üzenetek (üzleti szabály-jelek)
- FELIRTAM !!!

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
