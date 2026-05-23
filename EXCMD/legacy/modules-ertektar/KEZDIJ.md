# Legacy modul (ÉRTÉKTÁR): KEZDIJ

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/kezdij/debug/unit2.pas` (29353 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/kezdij/makedll/kezdij.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`kezdijatadorutin`

## DFM form(ok) / képernyő
`TForm1`, `TKDADVET`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · KDADVET · KEZEL · A KEZEL · BIZONYLATOK MEGTEKINT · VISSZA · Bizonylat sz · B-000666 · A123 · Konyvel · Bizonylat · El · Kezel · Mai napi bizonylatok · Bizonylat storn · Vissza a men · Mai napi kezel · STORNO · Nyomtat

## Eljárások / függvények (.pas)
`AlapAdatBeolvasas`, `AtadottKdKonyveloGombClick`, `AtvettKezdijEditEnter`, `AtvettKezdijEditExit`, `AtvettKezdijEditKeyDown`, `AtvettKdKonyvEloGombClick`, `AtvettKdKonyvMegsemGombClick`, `BizonylatChange`, `EvcomboChange`, `FormActivate`, `GetKezBizSzam`, `HoMegsemGombClick`, `HoOkeGombClick`, `KezbizracsCellClick`, `KezbizracsDblClick`, `KezbizracsKeyUp`, `KezbizracsMouseUp`, `KezbizvegegombClick`, `KezdAtvetGombClick`, `KezdBizonylatGombClick`, `KezbizStornoGombClick`, `KezdijNyomtatas`, `KezdKiadGombClick`, `KezdParancs`, `KezdPILLGombClick`, `KezdVISSZAGombClick`, `KiadottKezdijEditKeyDown`, `NapiKezdijDisplay`, `OldKezdijGombClick`, `PillKeszBackGombClick`

## Érintett adatbázis-táblák
`HARDWARE`, `KEZDIJ`, `KEZDIJDATA`, `PENZTAR`, `UTOLSOBLOKKOK`, `VTEMP`, `WPENZSZALLITAS`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM UTOLSOBLOKKOK`
- `SELECT * FROM KEZDIJDATA`
- `SELECT * FROM VTEMP`
- `DELETE FROM VTEMP`
- `INSERT INTO VTEMP (TIPUS,BIZONYLATSZAM,DATUM,ELOJEL,PENZTARKOD,`
- `INSERT INTO KEZDIJ (DATUM,BIZONYLAT,BANKJEGY,`
- `UPDATE UTOLSOBLOKKOK SET LASTKEZDIJ=`
- `SELECT * FROM WPENZSZALLITAS`
- `WHERE (WTIPUS=`
- `INSERT INTO KEZDIJ (DATUM,BIZONYLAT,ELOJEL,BANKJEGY,PENZTAR,STORNO)`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
