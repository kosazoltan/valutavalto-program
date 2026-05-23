# Legacy modul (SZERVER-FEJLESZT): KEZDIJ

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/kezdij/unit1.pas` (29991 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/kezdij/kezdij.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** A KEZEL · EGY NAP BEDOLGOZ · EGY H · KIL · << el · A PROGRAM  · VISSZA · dekanySoft · Form1 · Button1

## Eljárások / függvények (.pas)
`FormActivate`, `Makekezdtabla`, `Excelkeszites`, `Nulele`, `BitBtn8Click`, `EGYNAPBEGOMBClick`, `DATUMMEGSEMGOMBClick`, `ELOHOGOMBClick`, `KOVHOGOMBClick`, `DATUMOKEGOMBClick`, `BitBtn7Click`, `homegsemgombClick`, `hookegombClick`, `EVCOMBOChange`, `visszagombClick`, `FejlecKeszites`, `Keret`, `Hundatetostr`, `KezdtablaNyitas`, `TForm1.FormActivate`, `TForm1.DATUMOKEGOMBClick`, `TForm1.Nulele`, `Tform1.Makekezdtabla`, `TForm1.BitBtn8Click`, `TForm1.EGYNAPBEGOMBClick`, `TForm1.DATUMMEGSEMGOMBClick`, `TForm1.ELOHOGOMBClick`, `TForm1.KOVHOGOMBClick`, `TForm1.BitBtn7Click`, `TForm1.homegsemgombClick`

## Érintett adatbázis-táblák
`IRODAK`, `KEZD`

**SQL-műveletek (minta):**
- `SELECT * FROM IRODAK`
- `UPDATE`
- `SELECT * FROM`
- `WHERE (DATUM=`
- `WHERE PENZTAR=`
- `INSERT INTO`
- `SELECT * FROM KEZD`
- `+inttostr(_aktsor)];
  _range.select;
  _range.font.bold := true;
  _range.font.name :=`
- `WHERE CEGBETU=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
