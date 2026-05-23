# Legacy modul (SZERVER-FEJLESZT): SUMRATE

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/sumrate/unit1.pas` (13359 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/sumrate/project1.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · Button1 · Panel1 · Panel2

## Eljárások / függvények (.pas)
`Button1Click`, `IrodaBeolvasas`, `FormActivate`, `RateParancs`, `Nulele`, `KILEPOTimer`, `TForm1.FormActivate`, `TForm1.RateParancs`, `TForm1.Nulele`, `TForm1.Button1Click`, `TForm1.KILEPOTimer`

## Érintett adatbázis-táblák
`COMPRATE`, `IRODAK`

**SQL-műveletek (minta):**
- `DELETE FROM COMPRATE`
- `SELECT * FROM`
- `WHERE (ENGEDMENYTIPUS=32) OR (ENGEDMENYTIPUS=33)`
- `INSERT INTO COMPRATE (DATUM,PENZTAR,VALUTANEM,TRANZAKCIO,`
- `SELECT *  FROM`
- `SELECT * FROM COMPRATE`
- `WHERE`
- `INSERT INTO COMPRATE (DATUM,PENZTAR,VALUTANEM,TRANZAKCIO,ERTEKTAR`
- `UPDATE COMPRATE SET TRANZAKCIO=`
- `INSERT INTO COMPRATE (TRANZAKCIO`
- `SELECT * FROM IRODAK`
- `WHERE (CLOSED<>`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NINCS A HÓNAP FELDOLGOZVA !

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
