# Legacy modul (SZERVER-FEJLESZT): BOOKING

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/booking/save/booking/unit1.pas` (54375 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/booking/advetexcel/makedll/advetex.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`advetexcelrutin`

## DFM form(ok) / képernyő
`TForm1`, `TForm2`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · 0/ · EXCEL T · Label1 · 2021 · 2020 · 2019 · Janu · Augusztus · Junius · 2021 Szeptember · Febru · Szeptember · Okt · November · December · ADATLEGY · A v · dek@nySoft · EXCEL MEGNYIT · EGYIK SEM · Melyik excelt · FORGALMI T

## Eljárások / függvények (.pas)
`AdatlegyujtoProgram`, `AdatNullazas`, `AtadTablaGombClick`, `BookingControl`, `BookParancs`, `CtrlNullazas`, `E1Click`, `E1MouseMove`, `EgyiketseGombClick`, `ExitGombClick`, `EvPanelsClear`, `Excelopen`, `ExcelKill`, `Feldolgozas`, `GetCtrlData`, `ProgramFinish`, `FinishGombClick`, `ForgTablaGombClick`, `FormActivate`, `H1Click`, `H1MouseMove`, `HonapOkeGombClick`, `HoPanelsClear`, `PenztarBeolvasas`, `KilepoTimer`, `Konyveles`, `MakeAdvetTabla`, `MakeFdb`, `MakeTranzTabla`, `MakeEvhoTabla`

## Érintett adatbázis-táblák
`ATADATVET`, `EVHONAP`, `IRODAK`, `TRANZAKCIOK`

**SQL-műveletek (minta):**
- `SELECT FEJ.*,TET.*`
- `FROM`
- `WHERE (FEJ.STORNO=1)`
- `INSERT INTO TRANZAKCIOK (KFT,KORZET,PENZTAR,`
- `INSERT INTO ATADATVET (KFT,KORZET,PENZTAR,`
- `INSERT INTO EVHONAP (EV,HONAP)`
- `SELECT * FROM IRODAK ORDER BY CEGBETU,ERTEKTAR,UZLET`
- `SELECT * FROM IRODAK ORDER BY UZLET`
- `DELETE FROM TRANZAKCIOK`
- `DELETE FROM ATADATVET`
- `DELETE FROM EVHONAP`
- `SELECT * FROM`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
