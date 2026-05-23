# Legacy modul: HAVIZAR

> Forrás (primer): `Anti/VALUTA/DLL/HAVIZAR/MAKEDLL/Unit2.pas` (55736 karakter) · library: `DLL/HAVIZAR/MAKEDLL/Havizar.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`havizarorutin`

## DFM form(ok) / képernyő
`THAVIZARAS`

**Feliratok/gombok (Caption):** HAVIZARAS · HAVI Z · HAVIZ · Nyomtat

## Eljárások / függvények (.pas)
`Afairas`, `AlapadatBeolvasas`, `DataParancs`, `EtarHaviTradeTablo`, `EvComboChange`, `FejlecIras`, `Forgalomiras`, `ForgalomOsszesitesIras`, `FormActivate`, `GetElszamarfolyamok`, `HRKLista`, `HaviforgalomGyujtes`, `HaviKezdijRegeneralo`, `HaviNyitoAdatFeliras`, `HavizarasNyomtatas`, `HoOkeGombClick`, `HaviTrade`, `HzMake`, `KezkoltsegIras`, `Kozepreir`, `MegsemGombClick`, `WesternIras`, `UgyfelforgalomIras`, `Valparancs`, `VonalHuzo`, `WuAfaforgalom`, `WuDataClear`, `ZarokeszletIras`, `ArfForm`, `Elokieg`

## Érintett adatbázis-táblák
`HARDWARE`, `HAVIKEZELESIDIJ`, `HAVIMAT`, `HAVIOSSZESITO`, `HRKNAPLO`, `MATBIZONYLAT`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `SELECT FEJ.*,TET.*`
- `FROM`
- `WHERE (FEJ.STORNO=1)`
- `WHERE (STORNO=1) AND ((TIPUS=`
- `WHERE (STORNO=1) AND (MOZGAS>1)`
- `DELETE FROM HAVIKEZELESIDIJ`
- `WHERE HONAP=`
- `INSERT INTO HAVIKEZELESIDIJ (HONAP,NYITO,KEZELESIDIJ,KEZELESIDIJATVETEL,`
- `WHERE DATUM=`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`

## Felhasználói üzenetek (üzleti szabály-jelek)
- HIBA A HRK ZÁRÓÖSSZEGBEN

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
