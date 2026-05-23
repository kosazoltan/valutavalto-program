# Legacy modul (SZERVER-FEJLESZT mély): HRKGET

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/hrkatvevo/debug/unit2.pas` (35686 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/hrkatvevo/makedll/hrkget.dpr`
> Beágyazott sub-modul (a korábbi top-level generálás kihagyta). VALÓDI Delphi-forrás.

## Exportált API
`hrkatvevorutin`

## Eljárások / függvények
`AlapAdatBeolvasas`, `BizonylatChange`, `BePenztarEditKeyDown`, `FormActivate`, `GetHrkData`, `HrkForgDisplay`, `HrkParancs`, `HrkAtvevoGombClick`, `HrkBizonylatGombClick`, `HrkPILLGombClick`, `HrkRacsCellClick`, `HrkRacsKeyUp`, `HrkRacsMouseUp`, `HrkRacsDblClick`, `HrkAtadoGombClick`, `KiPenztarEditKeyDown`, `KiKunaEditKeyDown`, `KiKonyveloGombClick`, `SureGombClick`, `StornoGoGombClick`, `NoSureGombClick`, `IndokPanelKeyDown`, `KezdParancs`, `BeMegsemGombClick`, `KozepreIr`, `BeKunaEditEnter`, `BeKunaEditExit`, `BeKunaEditKeyDown`, `BeKonyveloGombClick`, `ListaVisszaGombClick`

## DFM Caption-ök
Form1 · INDIT · KILEP · FORM2 · HORV · BIZONYLATOK MEGTEKINT · VISSZA · Bizonylat sz · A fogad · A KEZEL · HRK · Bek · ID · BEV · KIAD · BIZONYLAT · Bizonylat storn · Vissza a men · A horv · STORNO · Nyomtat · BIZTOSAN STORN · IGEN · NEM · INDOKA:

## Adatbázis-táblák
`HARDWARE`, `HRKDATA`, `HRKNAPLO`, `HRKSZAMLAK`, `PENZTAR`, `VTEMP`

- `SELECT * FROM HRKNAPLO ORDER BY DATUM`
- `INSERT INTO HRKNAPLO (DATUM,IDO,NYITO,BEVETEL,KIADAS,ZARO)`
- `UPDATE HRKNAPLO SET BEVETEL=`
- `WHERE DATUM=`
- `SELECT * FROM HRKDATA`
- `UPDATE HRKDATA SET BESORSZAM=`
- `INSERT INTO HRKSZAMLAK (DATUM,IDO,BIZONYLATSZAM,BEVETEL,`
- `SELECT * FROM HRKSZAMLAK`
- `UPDATE HRKSZAMLAK SET STORNO=2 WHERE BIZONYLATSZAM=`
- `SELECT * FROM HARDWARE`

## Felhasználói üzenetek
_(nincs)_

## Megfeleltetés a jelenlegi programmal
_(a tényleges jelenlegi kód ellen verifikálandó.)_
