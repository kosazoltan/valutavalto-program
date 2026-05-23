# Legacy modul (SZERVER): JUTSZAMITO

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/jutszamito/debug/unit2.pas` (48321 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/jutszamito/makedll/dolgjutalek.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`jutalekszamitorutin`

## DFM form(ok) / képernyő
`TForm1`, `TJUTALEKFORM`

**Feliratok/gombok (Caption):** Form1 · Button1 · Button2 · Jutal · JUTAL · -T · -IG · SZ · KIL · SZORZ · BEST CHANGE ZRT · EXPRESSZ Z · ID · PT.SZ · FORGALOM · W.U. FORG · KEZ-I D · JUT. ALAP · JUT.MENTES · EXCELT · Excelt · AZ EXCELT · A JUTAL

## Eljárások / függvények (.pas)
`FormActivate`, `EvcomboChange`, `TolcomboChange`, `NapComboToltes`, `ArfolyamBeolvasas`, `KilepoGombClick`, `IgComboClick`, `StartGombClick`, `JutFreeBizonylatok`, `BlokkNyitas`, `JutalekSzamitas`, `jParancs`, `TaroltIdekBeolvasasa`, `MakeExcelTabla`, `Szorzoktombbe`, `IrodakTombbe`, `KilepoTimerTimer`, `DisplayTablaKijelzes`, `KilepesGombClick`, `excelgombClick`, `AdatAtadas`, `JutalekOsszesites`, `sJutParancs`, `MakeSumExcel`, `SetSzorzoGombClick`, `Nulele`, `JutalekFree`, `ScanIdPt`, `EzErtektar`, `ScanPros`

## Érintett adatbázis-táblák
`IRODAK`, `JUTALEK`, `JUTALEKSZORZO`, `PENZTAROSFORGALOM`, `PENZTAROSOK`

**SQL-műveletek (minta):**
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
- `SELECT * FROM IRODAK`
- `WHERE UZLET>150`

## Felhasználói üzenetek (üzleti szabály-jelek)
- HIBÁS ID-KÓD: 

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
