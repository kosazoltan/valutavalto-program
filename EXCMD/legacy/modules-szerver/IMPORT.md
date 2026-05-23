# Legacy modul (SZERVER): IMPORT

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/import/debug/unit2.pas` (40761 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/import/makedll/import.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`importfelirorutin`

## DFM form(ok) / képernyő
`TForm1`, `TMAKEIMPORT`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · Egy napi import  · IMPORT · IMPORT FILE  · KIL · CS · VISSZA A F

## Eljárások / függvények (.pas)
`AdatbazisUrito`, `AllomanyIras`, `AllomPrepare`, `BackToMenuGombClick`, `CimletGyujto`, `ElsoNapiKeszlet`, `EvKomboChange`, `ForgalomGyujto`, `FormCreate`, `HoKomboChange`, `ImportCancelClick`, `ImportGoClick`, `IrodaBeolvasas`, `NapKomboChange`, `ReceptorParancs`, `SetNapszam`, `UgyfelForgIras`, `WImport`, `IrasNyitas`, `Cimtarseek`, `DnemScan`, `Kerekito`, `Nulele`, `Otnulla`, `TegnapControl`, `TMakeImport.FormCreate`, `TMakeImport.ImportGoClick`, `TmakeImport.ForgalomGyujto`, `TMakeImport.AllomPrepare`, `TMakeImport.Otnulla`

## Érintett adatbázis-táblák
`IRODAK`, `SUMALLOMANY`, `SUMBANKFORGALOM`, `SUMUGYFELFORGALOM`

**SQL-műveletek (minta):**
- `SELECT FEJ.*,TET.*`
- `FROM`
- `WHERE (FEJ.DATUM=`
- `INSERT INTO SUMUGYFELFORGALOM (IRODASZAM,CEGBETU,BANKKOD,`
- `INSERT INTO SUMUGYFELFORGALOM (IRODASZAM,VALUTANEM,`
- `UPDATE SUMUGYFELFORGALOM SET BKARTYA=`
- `WHERE (IRODASZAM=`
- `Select * FROM`
- `WHERE DATUM<=`
- `WHERE DATUM=`
- `INSERT INTO SUMALLOMANY (IRODASZAM,CEGBETU,BANKKOD,`
- `SELECT * FROM SUMALLOMANY`

## Felhasználói üzenetek (üzleti szabály-jelek)
- Még nincs benn az összes zárás !

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
