# Legacy modul (SZERVER-FEJLESZT mély): PTARAK

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/penztarak/debug/unit2.pas` (95210 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/penztarak/makedll/ptarak.dpr`
> Beágyazott sub-modul (a korábbi top-level generálás kihagyta). VALÓDI Delphi-forrás.

## Exportált API
`penztarakrutin`

## Eljárások / függvények
`FormActivate`, `AdatDisplay`, `AdatFrissites`, `AdatFrissitoGombClick`, `AdatNullazo`, `AdatSummazas`, `AktaParancs`, `AktArfFeltoltes`, `AlapAdatBeolvasas`, `ArfolyamDisplay`, `ArfolyamTombClear`, `ArfolyamTombFeltoltes`, `BitBtn1Click`, `Button5Click`, `Button9Click`, `CsakEladasClick`, `CsakVasarClick`, `KeszForgtombFeltoltes`, `PkDekodolo`, `EgyPenztarDisplay`, `F1GombClick`, `F2GombClick`, `F3GombClick`, `FormCreate`, `FTPSzerverbeBelep`, `FrissitoTimerTimer`, `GrafikonDisplay`, `GrafikonGombClick`, `GrafikonPanelExit`, `IrodaAdatBeolvasas`

## DFM Caption-ök
Form1 · INDIT · KILEP · Pillanatnyi k · VALUTA · ELAD · 325,45 · 330,00 · AUD · AV2PAN · AE2PAN · BAM · AV19PAN · AE19PAN · PLN · AV4PAN · AE4PAN · BRL · AV5PAN · AE5PAN · CAD · AV6PAN · AE6PAN · CHF · AV7PAN

## Adatbázis-táblák
`AKTARF`, `ARFOLYAM`, `HARDWARE`, `IRODAK`, `PENZTAR`

- `SELECT * FROM IRODAK`
- `WHERE (CLOSED<>`
- `SELECT * FROM ARFOLYAM WHERE VALUTANEM=`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `DELETE FROM AKTARF`
- `INSERT INTO AKTARF (VALUTANEM,VETELIARFOLYAM,ELADASIARFOLYAM,`
- `SELECT * FROM AKTARF`
- `WHERE VALUTANEM<>`
- `UPDATE ARFOLYAM SET ELSZAMOLASIARFOLYAM=`

## Felhasználói üzenetek
- NEM SIKERÜLT AZ MNB ÁRFOLYAMOK LETÖLTÉSE
- NINCS A SZERVEREN MAI NAPI MNB ÁRFOLYAM RÖGZITVE
- NINCSENEK ÁRFOLYAMOK AZ ADATOKBAN

## Megfeleltetés a jelenlegi programmal
_(a tényleges jelenlegi kód ellen verifikálandó.)_
