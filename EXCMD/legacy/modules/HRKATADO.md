# Legacy modul: HRKATADO

> Forrás (primer): `Anti/VALUTA/DLL/HRKATADO/MAKEDLL/Unit2.pas` (28395 karakter) · library: `DLL/HRKATADO/MAKEDLL/Hrksend.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`hrkbekuldorutin`

## DFM form(ok) / képernyő
`TFORM2`

**Feliratok/gombok (Caption):** FORM2 · HORV · BIZONYLATOK MEGTEKINT · VISSZA · A KEZEL · Bizonylat sz · HRK · K-00666 · ID · BEV · KIAD · BIZONYLAT · Bizonylat storn · Vissza a men · A horv · STORNO · Nyomtat · BIZTOSAN STORNOZZA A BIZONYLATOT ? · IGEN · INDOKA: · STORN

## Eljárások / függvények (.pas)
`AlapAdatBeolvasas`, `BizonylatChange`, `FormActivate`, `GetHRKData`, `HrkForgDisplay`, `HrkParancs`, `HrkAtadGombClick`, `HrkBizonylatGombClick`, `HrkPILLGombClick`, `HrkRacsCellClick`, `HrkRacsKeyUp`, `HrkRacsMouseUp`, `HrkRacsDblClick`, `HrkRegen`, `KezdParancs`, `KezKonyvMegsemGombClick`, `KozepreIr`, `KunaEditEnter`, `KunaEditExit`, `KunaEditKeyDown`, `KonyveloGombClick`, `ListaVisszaGombClick`, `Naplobair`, `NaploParancs`, `Nyomtatas`, `PillKeszBackGombClick`, `PlombaAdatBeolvasas`, `ReprintGombClick`, `StornoGombClick`, `TextKiiro`

## Érintett adatbázis-táblák
`HARDWARE`, `HRKDATA`, `HRKNAPLO`, `HRKSZAMLAK`, `PENZTAR`, `VTEMP`

**SQL-műveletek (minta):**
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
- `SELECT * FROM PENZTAR`
- `SELECT * FROM VTEMP`

## Felhasználói üzenetek (üzleti szabály-jelek)
- Ennyi HRK nincs a házipénztárban !

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
