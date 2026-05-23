# Legacy modul (SZERVER-FEJLESZT): EXPEVNYITO

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/expevnyito/unit1.pas` (3369 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/expevnyito/project1.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · BitBtn1 · BitBtn2 · Panel1 · Panel2

## Eljárások / függvények (.pas)
`BitBtn2Click`, `BitBtn1Click`, `PParancs`, `Nulele`, `TForm1.BitBtn2Click`, `TForm1.BitBtn1Click`, `TForm1.PParancs`, `TForm1.Nulele`

## Érintett adatbázis-táblák
`ELOHAVI`, `ELONAPI`, `MAINCURR`

**SQL-műveletek (minta):**
- `DELETE FROM ELOHAVI`
- `WHERE EVHOSTRING<`
- `DELETE FROM ELONAPI`
- `WHERE DATUM<`
- `DELETE FROM MAINCURR`
- `WHERE EV<2019`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
