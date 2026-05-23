# Legacy modul (ÉRTÉKTÁR): HRKATVEVO **[ÉRTÉKTÁR-EGYEDI — nincs VALUTA megfelelő]**

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/hrkatvevo/debug/unit2.pas` (35686 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/hrkatvevo/makedll/hrkget.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`hrkatvevorutin`

## DFM form(ok) / képernyő
`TForm1`, `TFORM2`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · FORM2 · HORV · BIZONYLATOK MEGTEKINT · VISSZA · Bizonylat sz · A fogad · A KEZEL · HRK · Bek · ID · BEV · KIAD · BIZONYLAT · Bizonylat storn · Vissza a men · A horv · STORNO · Nyomtat · BIZTOSAN STORN · IGEN · NEM · INDOKA:

## Eljárások / függvények (.pas)
`AlapAdatBeolvasas`, `BizonylatChange`, `BePenztarEditKeyDown`, `FormActivate`, `GetHrkData`, `HrkForgDisplay`, `HrkParancs`, `HrkAtvevoGombClick`, `HrkBizonylatGombClick`, `HrkPILLGombClick`, `HrkRacsCellClick`, `HrkRacsKeyUp`, `HrkRacsMouseUp`, `HrkRacsDblClick`, `HrkAtadoGombClick`, `KiPenztarEditKeyDown`, `KiKunaEditKeyDown`, `KiKonyveloGombClick`, `SureGombClick`, `StornoGoGombClick`, `NoSureGombClick`, `IndokPanelKeyDown`, `KezdParancs`, `BeMegsemGombClick`, `KozepreIr`, `BeKunaEditEnter`, `BeKunaEditExit`, `BeKunaEditKeyDown`, `BeKonyveloGombClick`, `ListaVisszaGombClick`

## Érintett adatbázis-táblák
`HARDWARE`, `HRKDATA`, `HRKNAPLO`, `HRKSZAMLAK`, `PENZTAR`, `VTEMP`

**SQL-műveletek (minta):**
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
- `SELECT * FROM PENZTAR`
- `SELECT * FROM VTEMP`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
