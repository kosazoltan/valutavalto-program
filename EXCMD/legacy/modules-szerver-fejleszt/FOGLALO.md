# Legacy modul (SZERVER-FEJLESZT): FOGLALO

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/foglalo/unit1.pas` (16132 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/foglalo/foglalo.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** A FOGLAL · KIL · EXCEL T

## Eljárások / függvények (.pas)
`FormActivate`, `KILEPOGOMBClick`, `RangefontKeszlet`, `GetFoglalasok`, `ExcelKeszites`, `Scanetar`, `STARTGOMBClick`, `ScanIroda`, `KILEPOTIMERTimer`, `TForm1.FormActivate`, `TForm1.STARTGOMBClick`, `TForm1.GetFoglalasok`, `TForm1.excelkeszites`, `TForm1.RangefontKeszlet`, `TForm1.ScanIroda`, `TForm1.KILEPOGOMBClick`, `TForm1.Scanetar`, `TForm1.KILEPOTIMERTimer`

## Érintett adatbázis-táblák
_(nincs explicit SQL-tábla)_

**SQL-műveletek (minta):**
- `;

      _oxl.workbooks[1].worksheets[_korzetindex].name := _kztNev;
      _oxl.workbooks[1].worksheets[_korzetindex].select;
      _range := _oxl.range[`

## Felhasználói üzenetek (üzleti szabály-jelek)
- Nem sikerült csatlakozni a szerverhez !
- Nem sikerült belépni a FOGLALO-könyvtárába !

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
