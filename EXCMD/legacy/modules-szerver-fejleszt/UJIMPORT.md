# Legacy modul (SZERVER-FEJLESZT mély): UJIMPORT

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/ugyfelcontrol/dll/ujimport/debug/unit2.pas` (35730 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/ugyfelcontrol/dll/ujimport/makedll/ujimport.dpr`
> Beágyazott sub-modul (a korábbi top-level generálás kihagyta). VALÓDI Delphi-forrás.

## Exportált API
`ujimportkeszito`

## Eljárások / függvények
`FormCreate`, `Button1Click`, `FormActivate`, `NAPTARChange`, `ELOHOGOMBClick`, `KOVHOGOMBClick`, `VISSZAGOMBClick`, `DATUMOKEGOMBClick`, `Korrekcio`, `Irodakbetoltese`, `Bizonylatgyujtes`, `Bazisbairas`, `ImpParancs`, `BizParancs`, `BizonylatFeliras`, `VegFeldolgozas`, `GetNaturData`, `Joginullazas`, `MbNullazas`, `Naturnullazas`, `GetJogiData`, `ImportFileRogzites`, `FejlecBeirasa`, `Lakcimbonto`, `GetOkmtip`, `Pontoz`, `ScanPenztar`, `Nulele`, `Timportform.FormCreate`, `TIMPORTFORM.Button1Click`

## DFM Caption-ök
Form1 · INDIT · KILEP · IMPORTFORM · EL · 2022.01.01 · VISSZA A F

## Adatbázis-táblák
`BIZONYLATOK`, `IMPORT`, `IRODAK`, `JOGI`, `JOGIBIZ`

- `SELECT * FROM`
- `WHERE (DATUM=`
- `SELECT * FROM JOGIBIZ`
- `SELECT * FROM IRODAK`
- `WHERE STATUS=`
- `INSERT INTO IMPORT (UGYFELTIPUS,BANKKOD,DATUM,BANKJEGY,VALUTANEM,`
- `DELETE FROM BIZONYLATOK`
- `INSERT INTO BIZONYLATOK (BIZONYLATSZAM,PENZTAR,NEVTABLA,SORSZAM)`
- `DELETE FROM IMPORT`
- `SELECT * FROM BIZONYLATOK`

## Felhasználói üzenetek
- A KÉRT DÁTUM MAJD A JÖVŐBEN LESZ

## Megfeleltetés a jelenlegi programmal
_(a tényleges jelenlegi kód ellen verifikálandó.)_
