# Legacy modul (SZERVER-FEJLESZT mély): LEGYUJTO

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/adatgyujto/debug/unit2.pas` (95468 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/adatgyujto/makedll/legyujto.dpr`
> Beágyazott sub-modul (a korábbi top-level generálás kihagyta). VALÓDI Delphi-forrás.

## Exportált API
`adatlegyujtorutin`

## Eljárások / függvények
`FormActivate`, `IrodaBetolto`, `Idoszakbeolvasas`, `GetLastdaysRates`, `CimletGyujtes`, `ForgalomGyujtes`, `ForgalomRutin`, `SendingRutin`, `StornoRegisztracio`, `BankGyujtes`, `TRBGyujtes`, `InterPtControl`, `TRBControl`, `WuniNullazas`, `WuniForgalomGyujtes`, `GetWuniNyitasZaras`, `MetroForgalomGyujtes`, `TescoForgalomGyujtes`, `WuniAfaBerogzites`, `MNBArfolyamLetoltes`, `KeszletKorzetSummazas`, `KeszletKorzetSumNullazo`, `KeszletKorzetSumRogzito`, `KeszletKftSummazas`, `KeszletKftSumRogzito`, `KeszletCegSummazas`, `KeszletCegSumNullazo`, `KeszletCegSumRogzito`, `ForgKorzetSummazas`, `ForgKorzetSumNullazo`

## DFM Caption-ök
Form1 · INDIT · KILEP · ADATLEGYUJTES · AZ ADATOK LEGY

## Adatbázis-táblák
`ARFOLYAM`, `CIMLETGYUJTO`, `DTABLA`, `FORGALOMGYUJTO`, `IDOSZAK`, `IRODAK`, `PENZTARKOZOTT`, `STORNOFEJ`, `STORNOTETEL`, `SUMBANKFORGALOM`, `TRBGYUJTO`, `WUNIGYUJTO`

- `SELECT * FROM`
- `WHERE DATUM<=`
- `WHERE DATUM=`
- `INSERT INTO CIMLETGYUJTO (IRODASZAM,ERTEKTAR,CEGBETU,`
- `SELECT FEJ.*, TET.*`
- `FROM`
- `WHERE`
- `SELECT * FROM FORGALOMGYUJTO`
- `WHERE IRODASZAM=`
- `INSERT INTO FORGALOMGYUJTO (VALUTANEM,IRODASZAM,CEGBETU,`

## Felhasználói üzenetek
_(nincs)_

## Megfeleltetés a jelenlegi programmal
_(a tényleges jelenlegi kód ellen verifikálandó.)_
