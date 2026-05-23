# Legacy modul (SZERVER-FEJLESZT): JUTMEND

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/jutmend/unit1.pas` (9869 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/jutmend/jutmend.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · EXCLUSIVE BEST CHANGE JUTAL · KIL

## Eljárások / függvények (.pas)
`EgyPenztarJavitasa`, `BFAdatbazisJavitasa`, `WuniAdatbazisJavitasa`, `BitBtn1Click`, `FormActivate`, `EVEDITEnter`, `EVEDITExit`, `HONAPOKEGOMBClick`, `ValutaParancs`, `Nulele`, `Scanid`, `Marasorban`, `TForm1.FormActivate`, `TForm1.HONAPOKEGOMBClick`, `TForm1.EgyPenztarJavitasa`, `TForm1.BFadatbazisJavitasa`, `TForm1.WuniadatbazisJavitasa`, `TForm1.Marasorban`, `TForm1.Scanid`, `TForm1.EVEDITEnter`, `TForm1.EVEDITExit`, `TForm1.ValutaParancs`, `TForm1.Nulele`, `TForm1.BitBtn1Click`

## Érintett adatbázis-táblák
`PENZTAROSOK`

**SQL-műveletek (minta):**
- `SELECT * FROM PENZTAROSOK ORDER BY IDKOD`
- `SELECT * FROM`
- `WHERE ((TIPUS=`
- `UPDATE`
- `WHERE IDKOD=`
- `WHERE (UGYFELTIPUS=`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
