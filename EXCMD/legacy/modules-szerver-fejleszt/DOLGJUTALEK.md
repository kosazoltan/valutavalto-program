# Legacy modul (SZERVER-FEJLESZT mély): DOLGJUTALEK

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/jutszamito/debug/unit2.pas` (48321 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/jutszamito/makedll/dolgjutalek.dpr`
> Beágyazott sub-modul (a korábbi top-level generálás kihagyta). VALÓDI Delphi-forrás.

## Exportált API
`jutalekszamitorutin`

## Eljárások / függvények
`FormActivate`, `EvcomboChange`, `TolcomboChange`, `NapComboToltes`, `ArfolyamBeolvasas`, `KilepoGombClick`, `IgComboClick`, `StartGombClick`, `JutFreeBizonylatok`, `BlokkNyitas`, `JutalekSzamitas`, `jParancs`, `TaroltIdekBeolvasasa`, `MakeExcelTabla`, `Szorzoktombbe`, `IrodakTombbe`, `KilepoTimerTimer`, `DisplayTablaKijelzes`, `KilepesGombClick`, `excelgombClick`, `AdatAtadas`, `JutalekOsszesites`, `sJutParancs`, `MakeSumExcel`, `SetSzorzoGombClick`, `Nulele`, `JutalekFree`, `ScanIdPt`, `EzErtektar`, `ScanPros`

## DFM Caption-ök
Form1 · Button1 · Button2 · Jutal · JUTAL · -T · -IG · SZ · KIL · SZORZ · BEST CHANGE ZRT · EXPRESSZ Z · ID · PT.SZ · FORGALOM · W.U. FORG · KEZ-I D · JUT. ALAP · JUT.MENTES · EXCELT · Excelt · AZ EXCELT · A JUTAL

## Adatbázis-táblák
`IRODAK`, `JUTALEK`, `JUTALEKSZORZO`, `PENZTAROSFORGALOM`, `PENZTAROSOK`

- `SELECT * FROM`
- `WHERE (STORNO=1) AND (DATUM BETWEEN`
- `WHERE VALUTANEM=`
- `WHERE ENGEDMENYTIPUS=34`
- `WHERE (STORNO=1) AND ((TIPUS=`
- `DELETE FROM PENZTAROSFORGALOM`
- `INSERT INTO PENZTAROSFORGALOM (IDKOD,PENZTAROSNEV,PENZTARIFORGALOM,`
- `SELECT * FROM PENZTAROSFORGALOM`
- `SELECT * FROM JUTALEKSZORZO`
- `SELECT * FROM PENZTAROSOK`

## Felhasználói üzenetek
- HIBÁS ID-KÓD: 

## Megfeleltetés a jelenlegi programmal
_(a tényleges jelenlegi kód ellen verifikálandó.)_
