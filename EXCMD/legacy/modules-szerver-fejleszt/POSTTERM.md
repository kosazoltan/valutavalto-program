# Legacy modul (SZERVER-FEJLESZT): POSTTERM

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/postterm/unit1.pas` (31074 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/postterm/posterm.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** POS-TERMINAL TRANZAKCI · Az Excel-t · bem · POSTA\POSTERM · EXCEL K

## Eljárások / függvények (.pas)
`ExitGombClick`, `MakePostTabla`, `PostParancs`, `FormActivate`, `HOOKEGOMBClick`, `BankKodBeolvasas`, `MakeExcel`, `Keret`, `Keret2`, `Nulele`, `Ezertektar`, `EvComboChange`, `ExcelKill`, `ScanBankKod`, `NAPCOMBOChange`, `AdatGyujtes`, `TForm1.FormActivate`, `TForm1.BankKodBeolvasas`, `TForm1.HOOKEGOMBClick`, `TForm1.Ezertektar`, `TForm1.MakeExcel`, `TForm1.Keret`, `TForm1.Keret2`, `TForm1.EVCOMBOChange`, `TForm1.ExcelKill`, `TForm1.ScanBankKod`, `TForm1.NAPCOMBOChange`, `TForm1.Adatgyujtes`, `TForm1.PostParancs`, `TForm1.MakePostTabla`

## Érintett adatbázis-táblák
`IRODAK`

**SQL-műveletek (minta):**
- `SELECT * FROM IRODAK`
- `WHERE CLOSED=`
- `DELETE FROM`
- `INSERT INTO`
- `SELECT * FROM`
- `WHERE CEGBETU=`
- `WHERE (FIZETOESZKOZ=2) AND (STORNO=1)`

## Felhasználói üzenetek (üzleti szabály-jelek)
- HIBÁS ÉV

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
