# Legacy modul (SZERVER-FEJLESZT): PTFORG

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/ptforg/unit1.pas` (15122 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/ptforg/ptarctrl.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`, `TEREDMENYFORM`, `TBEMUTATO`, `THOBEKERO`

**Feliratok/gombok (Caption):** Form1 · KIL · EREDM · EREDMENYFORM · VISSZA A MEN · FOGAD · FOGADVA · VALNEM · ELT · (A kiv · AZ  · BEMUTATO · VISSZA · ID · BIZONYLAT · PLOMBA · SZ · HOBEKERO · okt · janu · november · febru · augusztus · szeptember · december

## Eljárások / függvények (.pas)
`BitBtn2Click`, `Ptarbeolvasas`, `Tree`, `PtParancs`, `Nulele`, `FormActivate`, `INDITOTimer`, `ScanKVar`, `ScanFVar`, `EREDMENYGOMBClick`, `KILEPOTimer`, `TForm1.FormActivate`, `TForm1.INDITOTimer`, `TForm1.ScanKVar`, `TForm1.ScanFVar`, `TForm1.Nulele`, `Tform1.PtParancs`, `TForm1.PtarBeolvasas`, `TForm1.BitBtn2Click`, `TForm1.Tree`, `TForm1.EREDMENYGOMBClick`, `TForm1.KILEPOTimer`

## Érintett adatbázis-táblák
`COMPARE`, `IRODAK`

**SQL-műveletek (minta):**
- `DELETE FROM COMPARE`
- `SELECT FEJ.*, TET.*`
- `FROM`
- `WHERE (FEJ.STORNO=1) AND ((FEJ.TIPUS=`
- `INSERT INTO COMPARE (KULDO,FOGADO,VALUTANEM,DATUM,`
- `WHERE (KULDO=`
- `SELECT * FROM COMPARE`
- `UPDATE COMPARE SET FOGADOTTBANKJEGY=`
- `SELECT * FROM IRODAK ORDER BY UZLET`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
