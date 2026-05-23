# Legacy modul (SZERVER-FEJLESZT): JOGISZEMELY

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/jogiszemely/unit1.pas` (19636 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/jogiszemely/jogiszem.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm2`, `TForm3`

**Feliratok/gombok (Caption):** JOGI SZEM · <<<   EL · 2022 SZEPTEMBER 30 · AZ EXCELT · C:\JOGISZEMELY\EXCEL · KIL · JG220405.XLSX · Form3 · EXCELT

## Eljárások / függvények (.pas)
`BitBtn2Click`, `BitBtn1Click`, `BitBtn3Click`, `GyujtoParancs`, `GyujtoBeiras`, `DaybookControl`, `FormActivate`, `HonapOkeGombClick`, `KilepoGombClick`, `Levalogatas`, `NaptarKeyUp`, `NaptarDblClick`, `NaptarValtozott`, `PenztarBeolvasas`, `TulajKiolvasas`, `ExcelKill`, `Ezertektar`, `Nulele`, `ScanPtar`, `TForm2.FormActivate`, `TForm2.BitBtn2Click`, `TForm2.HONAPOKEGOMBClick`, `Tform2.PenztarBeolvasas`, `TForm2.ScanPtar`, `TForm2.Nulele`, `TForm2.Levalogatas`, `TForm2.KilepoGombClick`, `TForm2.ExcelKill`, `Tform2.Ezertektar`, `TForm2.NAPTARValtozott`

## Érintett adatbázis-táblák
`GYUJTO`, `IRODAK`, `JOGI`

**SQL-műveletek (minta):**
- `SELECT * FROM IRODAK`
- `DELETE FROM GYUJTO`
- `SELECT * FROM`
- `WHERE DATUM=`
- `WHERE BIZONYLATSZAM=`
- `SELECT * FROM JOGI WHERE SORSZAM=`
- `INSERT INTO GYUJTO (PENZTAR,BIZONYLATSZAM,JOGINEV,TELEPHELYCIM,ADOSZAM,`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
