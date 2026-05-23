# Legacy modul (SZERVER-FEJLESZT mély): FORGEX

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/booking/forgexel/debug/unit2.pas` (34307 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/booking/forgexel/makedll/forgex.dpr`
> Beágyazott sub-modul (a korábbi top-level generálás kihagyta). VALÓDI Delphi-forrás.

## Exportált API
`forgalomexcelrutin`

## Eljárások / függvények
`AdatLezaras`, `EgyKftExcelKeszitese`, `FejlecekKeszitese`, `FormActivate`, `KilepoTimer`, `KillExcel`, `KftFejlec`, `KftOsszesitese`, `KftSummazas`, `MakeForgExcel`, `PenztarBeolvasas`, `PenztarExcelTombRendezes`, `SumNullazas`, `VastagKeret`, `VekonyKeret`, `UjKorzetNyitas`, `UjPenztarNyitas`, `Nulele`, `ScanPenztar`, `ScanKorzet`, `ScanValuta`, `GetKorzetnev`, `TForm2.FormActivate`, `TForm2.MakeForgExcel`, `TForm2.FejlecekKeszitese`, `TForm2.KftFejlec`, `TForm2.EgyKftExcelKeszitese`, `Tform2.UjKorzetNyitas`, `TForm2.Ujpenztarnyitas`, `TForm2.AdatLezaras`

## DFM Caption-ök
Form1 · INDIT · KILEP · Form2 · FORGALMI ADATOK EXCELT

## Adatbázis-táblák
`EVHONAP`, `IRODAK`, `TRANZAKCIOK`

- `SELECT * FROM EVHONAP`
- `,_kftindex);

  // A fejléc alatti sor befagyasztása

  _oxl.workbooks[1].worksheets[_kftindex].select;

  _rangestr :=`
- `SELECT * FROM TRANZAKCIOK`
- `WHERE KFT=`
- `SELECT * FROM IRODAK ORDER BY CEGBETU,ERTEKTAR,UZLET`
- `SELECT * FROM IRODAK ORDER BY UZLET`

## Felhasználói üzenetek
_(nincs)_

## Megfeleltetés a jelenlegi programmal
_(a tényleges jelenlegi kód ellen verifikálandó.)_
