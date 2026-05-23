# Legacy modul (SZERVER-FEJLESZT mély): HRKSEND

> Forrás (primer): `Anti/VALUTA/DLL/HRKATADO/DEBUG/Unit2.pas` (28395 karakter) · library: `Anti/VALUTA/DLL/HRKATADO/MAKEDLL/Hrksend.dpr`
> Beágyazott sub-modul (a korábbi top-level generálás kihagyta). VALÓDI Delphi-forrás.

## Exportált API
`hrkbekuldorutin`

## Eljárások / függvények
`AlapAdatBeolvasas`, `BizonylatChange`, `FormActivate`, `GetHRKData`, `HrkForgDisplay`, `HrkParancs`, `HrkAtadGombClick`, `HrkBizonylatGombClick`, `HrkPILLGombClick`, `HrkRacsCellClick`, `HrkRacsKeyUp`, `HrkRacsMouseUp`, `HrkRacsDblClick`, `HrkRegen`, `KezdParancs`, `KezKonyvMegsemGombClick`, `KozepreIr`, `KunaEditEnter`, `KunaEditExit`, `KunaEditKeyDown`, `KonyveloGombClick`, `ListaVisszaGombClick`, `Naplobair`, `NaploParancs`, `Nyomtatas`, `PillKeszBackGombClick`, `PlombaAdatBeolvasas`, `ReprintGombClick`, `StornoGombClick`, `TextKiiro`

## DFM Caption-ök
Form1 · INDIT · KILEP · FORM2 · HORV · BIZONYLATOK MEGTEKINT · VISSZA · A KEZEL · Bizonylat sz · HRK · K-00666 · ID · BEV · KIAD · BIZONYLAT · Bizonylat storn · Vissza a men · A horv · STORNO · Nyomtat · BIZTOSAN STORNOZZA A BIZONYLATOT ? · IGEN · INDOKA: · STORN

## Adatbázis-táblák
`HARDWARE`, `HRKDATA`, `HRKNAPLO`, `HRKSZAMLAK`, `PENZTAR`, `VTEMP`

- `SELECT * FROM HRKNAPLO ORDER BY DATUM`
- `INSERT INTO HRKNAPLO (DATUM,IDO,NYITO,BEVETEL,KIADAS,ZARO)`
- `UPDATE HRKNAPLO SET KIADAS=`
- `WHERE DATUM=`
- `SELECT * FROM HRKDATA`
- `UPDATE HRKDATA SET KISORSZAM=`
- `INSERT INTO HRKSZAMLAK (DATUM,IDO,BIZONYLATSZAM,KIADAS,`
- `SELECT * FROM HRKSZAMLAK`
- `UPDATE HRKSZAMLAK SET STORNO=2 WHERE BIZONYLATSZAM=`
- `SELECT * FROM HARDWARE`

## Felhasználói üzenetek
- Ennyi HRK nincs a házipénztárban !

## Megfeleltetés a jelenlegi programmal
_(a tényleges jelenlegi kód ellen verifikálandó.)_
