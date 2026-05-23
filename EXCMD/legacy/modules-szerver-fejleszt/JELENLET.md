# Legacy modul (SZERVER-FEJLESZT): JELENLET

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/jelenlet/unit1.pas` (19049 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/jelenlet/jelenlet.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Havi jelenl · HAVI JELENL · EXCEL T · KIL

## Eljárások / függvények (.pas)
`xForma`, `MakeexcelTabla`, `GetOszlopstring`, `Nulele`, `Scanidkod`, `RangefontKeszlet`, `KILEPOTIMERTimer`, `GetMezo`, `ScanKorzet`, `setido`, `FormActivate`, `STARTGOMBClick`, `QUITGOMBClick`, `EVCOMBOChange`, `TForm1.FormActivate`, `TForm1.StartGombClick`, `TForm1.MakeExcelTabla`, `TForm1.xForma`, `tForm1.Scanidkod`, `TForm1.GetMezo`, `TForm1.ScanKorzet`, `TForm1.KILEPOTIMERTimer`, `TForm1.Nulele`, `TForm1.setido`, `TForm1.RangefontKeszlet`, `TForm1.GetOszlopstring`, `TForm1.QUITGOMBClick`, `TForm1.EVCOMBOChange`

## Érintett adatbázis-táblák
_(nincs explicit SQL-tábla)_

**SQL-műveletek (minta):**
- `;
       _oxl.workbooks[1].worksheets[_korzetindex].name := _kNev;
       _oxl.workbooks[1].worksheets[_korzetindex].select;
       _range := _oxl.range[`
- `];
       _range.select;
       _oxl.Activewindow.FreezePanes := True;

       _rangestr :=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- Nem sikerült csatlakozni a szerverhez !
- Nem sikerült belépni a JELENLET-könyvtárába !

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
