# Legacy modul (SZERVER-FEJLESZT): ARCHIVAL

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/archival/unit1.pas` (4372 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/archival/project1.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · dekanySoft · ARCHIV · KIL

## Eljárások / függvények (.pas)
`STARTGOMBClick`, `getTablaNevek`, `ibparancs`, `ENDGOMBClick`, `FormActivate`, `TForm1.STARTGOMBClick`, `TForm1.ibparancs`, `TForm1.getTablaNevek`, `TForm1.ENDGOMBClick`, `TForm1.FormActivate`

## Érintett adatbázis-táblák
`RDB`

**SQL-műveletek (minta):**
- `SELECT RDB$RELATION_NAME FROM RDB$RELATIONS`
- `WHERE RDB$FLAGS=1`

## Felhasználói üzenetek (üzleti szabály-jelek)
- AZ IDEI ARCHIVÁLÁS MÁR MEGTÖRTÉNT !
- NEM SIKERÜLT A VALDATA.FDB-T ELMÁSOLNI !
- NEM TALÁLT EGYETLEN TÁBLÁT SEM A VALDATÁBAN !?

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
