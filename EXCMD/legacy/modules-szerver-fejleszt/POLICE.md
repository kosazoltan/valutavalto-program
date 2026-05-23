# Legacy modul (SZERVER-FEJLESZT): POLICE

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/police/1/unit1.pas` (8185 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/police/project1.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · REND · START · KIL · BEDOLGOZ · Panel1 · Panel2 · KILEP · DISPLAY

## Eljárások / függvények (.pas)
`Button2Click`, `Button1Click`, `PoliceBejegyzes`, `Polparancs`, `Ezertektar`, `FormActivate`, `TForm1.Button2Click`, `TForm1.Button1Click`, `TForm1.Ezertektar`, `TForm1.Policebejegyzes`, `TForm1.PolParancs`, `TForm1.FormActivate`

## Érintett adatbázis-táblák
`IRODAK`, `POLICE`, `UGYFELEK`

**SQL-műveletek (minta):**
- `DELETE FROM POLICE`
- `SELECT * FROM`
- `WHERE (VALUTANEM=`
- `WHERE BIZONYLATSZAM=`
- `SELECT * FROM UGYFELEK`
- `WHERE UGYFELSZAM=`
- `INSERT INTO POLICE (PENZTAR,PENZTARNEV,DATUM,IDO,BANKJEGY,FTERTEK,`
- `SELECT * FROM IRODAK`

## Felhasználói üzenetek (üzleti szabály-jelek)
- LEVÁLOGATVA !!!!

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
