# Legacy modul (SZERVER-FEJLESZT mély): EVIMAX

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/ugyfelcontrol/dll/evimax/debug/unit2.pas` (24706 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/ugyfelcontrol/dll/evimax/makedll/evimax.dpr`
> Beágyazott sub-modul (a korábbi top-level generálás kihagyta). VALÓDI Delphi-forrás.

## Exportált API
`evimaxtranzakciok`

## Eljárások / függvények
`FormActivate`, `EvEditKeyDown`, `ForintEditKeyDown`, `EvEditEnter`, `EvEditExit`, `StartGombClick`, `ZapDbase`, `Vastag`, `Vekony`, `VisszaGombClick`, `ZaroGombClick`, `NaturDataBeiras`, `JogiDataBeiras`, `Bovito`, `Forintform`, `TForm2.FormActivate`, `TForm2.EVEDITKeyDown`, `TForm2.FORINTEDITKeyDown`, `TForm2.Forintform`, `TForm2.EVEDITEnter`, `TForm2.EVEDITExit`, `TForm2.STARTGOMBClick`, `TForm2.Bovito`, `TForm2.Zapdbase`, `TForm2.Vastag`, `TForm2.Vekony`, `TForm2.ZAROGOMBClick`, `TForm2.VISSZAGOMBClick`, `TForm2.NaturDataBeiras`, `TForm2.JogiDataBeiras`

## DFM Caption-ök
Form1 · INDIT · KILEP · Form2 · Ft · LEGY · VISSZA A MEN · ADATOK LEGY

## Adatbázis-táblák
`JOGI`, `JOGISZEMELY`, `UGYFELEK`

- `SELECT * FROM`
- `WHERE FORINTOSSZEG>=`
- `INSERT INTO UGYFELEK (NEV,SORSZAM,ANYJANEVE,SZULETESIHELY,`
- `SELECT * FROM JOGI`
- `INSERT INTO JOGISZEMELY (JOGISZEMELYNEV,TELEPHELYCIM,`
- `DELETE FROM UGYFELEK`
- `DELETE FROM JOGISZEMELY`
- `SELECT * FROM UGYFELEK ORDER BY EVESFORINT DESC`
- `SELECT * FROM JOGISZEMELY ORDER BY EVESFORINT DESC`

## Felhasználói üzenetek
- ÉRVÉNYTELEN ÉV
- NINCSENEK ADATOK

## Megfeleltetés a jelenlegi programmal
_(a tényleges jelenlegi kód ellen verifikálandó.)_
