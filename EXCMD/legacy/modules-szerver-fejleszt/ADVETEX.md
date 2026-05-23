# Legacy modul (SZERVER-FEJLESZT mély): ADVETEX

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/booking/advetexcel/debug/unit2.pas` (21479 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/booking/advetexcel/makedll/advetex.dpr`
> Beágyazott sub-modul (a korábbi top-level generálás kihagyta). VALÓDI Delphi-forrás.

## Exportált API
`advetexcelrutin`

## Eljárások / függvények
`AdatLezaras`, `AdatokBeirasa`, `IrodaBeolvasas`, `FormActivate`, `KillExcel`, `MunkaMenet`, `KFTFejlec`, `KilepoTimer`, `EgyAdatSorBeirasa`, `UjKorzetNyitas`, `Ujpenztarnyitas`, `VastagKeret`, `VekonyKeret`, `GetKorzetnev`, `Kiez`, `Nulele`, `ScanKorzet`, `TForm2.FormActivate`, `TForm2.KilepoTimer`, `TForm2.Munkamenet`, `TForm2.KFTFejlec`, `TForm2.Adatokbeirasa`, `TForm2.EgyadatsorBeirasa`, `TForm2.Ujkorzetnyitas`, `TForm2.GetKorzetnev`, `TForm2.ScanKorzet`, `TForm2.AdatLezaras`, `TForm2.Ujpenztarnyitas`, `TForm2.Nulele`, `TForm2.Vastagkeret`

## DFM Caption-ök
Form1 · INDIT · KILEP · 0/ · EXCEL T

## Adatbázis-táblák
`EVHONAP`, `IRODAK`

- `SELECT * FROM EVHONAP`
- `;
  VastagKeret(_rangestr,_kftindex);

  // Fagyasztások:

  _oxl.workbooks[1].worksheets[_kftindex].select;
  _rangestr :=`
- `WHERE KFT=`
- `SELECT * FROM IRODAK`

## Felhasználói üzenetek
_(nincs)_

## Megfeleltetés a jelenlegi programmal
_(a tényleges jelenlegi kód ellen verifikálandó.)_
