# Legacy modul (SZERVER-FEJLESZT mély): KESZEX

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/booking/keszexcel/debug/unit2.pas` (24872 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/booking/keszexcel/makedll/keszex.dpr`
> Beágyazott sub-modul (a korábbi top-level generálás kihagyta). VALÓDI Delphi-forrás.

## Exportált API
`keszletexcelrutin`

## Eljárások / függvények
`AdatLezaras`, `EgyKftExcelKeszitese`, `Kftfejlec`, `FormActivate`, `IrodaBeolvasas`, `Munkamenet`, `KftSummazas`, `KillExcel`, `KilepoTimer`, `KftSumKiirasa`, `Sumnullazas`, `UjkorzetNyitas`, `UjPenztarNyitas`, `VastagKeret`, `VekonyKeret`, `Nulele`, `ScanPenztar`, `Getpenztarnev`, `GetKorzetnev`, `Scankorzet`, `ScanDnem`, `TForm2.FormActivate`, `TForm2.Munkamenet`, `TForm2.Kftfejlec`, `TForm2.KilepoTimer`, `TForm2.Vastagkeret`, `TForm2.Vekonykeret`, `TForm2.Nulele`, `TForm2.KillExcel`, `TForm2.IrodaBeolvasas`

## DFM Caption-ök
Form1 · INDIT · KILEP · Form2 · HAVI NYIT · MEGHAT

## Adatbázis-táblák
`EVHONAP`, `IRODAK`, `TRANZAKCIOK`

- `SELECT * FROM EVHONAP`
- `;
  VastagKeret(_rangestr,_kftindex);

  // Fagyasztások:

  _oxl.workbooks[1].worksheets[_kftindex].select;
  _rangestr :=`
- `SELECT * FROM IRODAK`
- `SELECT *FROM TRANZAKCIOK`
- `WHERE KFT=`

## Felhasználói üzenetek
_(nincs)_

## Megfeleltetés a jelenlegi programmal
_(a tényleges jelenlegi kód ellen verifikálandó.)_
