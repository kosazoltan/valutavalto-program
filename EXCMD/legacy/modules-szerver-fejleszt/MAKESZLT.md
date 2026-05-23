# Legacy modul (SZERVER-FEJLESZT): MAKESZLT

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/makeszlt/unit1.pas` (79706 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/makeszlt/keszlex.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`, `TACEXCELTABLA`, `TEXPRESSEXCEL`, `TMAKEEXCELTABLA`

**Feliratok/gombok (Caption):** Form1 · AKTU · Verzi · KIL · ART-CASH KFT EXCEL-F · EXPRESSEXCEL · EXPRESSZ EXCEL · EXCEL K

## Eljárások / függvények (.pas)
`FormActivate`, `InditoTimer`, `GetFoglalodnemSorszam`, `KILEPOGOMBClick`, `AdatNullazo`, `AdatOsszesites`, `MakeExcelTabla`, `RangeKozepre`, `KorzetExcelFejlec`, `ExcelAdatFeltoltes`, `KorzetOsszesenExcel`, `KftOsszesenExcel`, `FoglalokBedolgozasa`, `AcAdatOsszesites`, `AcEvaulate`, `AcScanIroda`, `AcPkBeolvasasa`, `RangefontKeszlet`, `FTForm`, `GetOszlopBetu`, `ScanDnem`, `ScanKorzet`, `Nulele`, `KeforTempBeolvasasa`, `TForm1.FormActivate`, `TForm1.InditoTimer`, `TForm1.KeforTempBeolvasasa`, `TForm1.AdatOsszesites`, `TForm1.ScanDnem`, `TForm1.AdatNullazo`

## Érintett adatbázis-táblák
_(nincs explicit SQL-tábla)_

**SQL-műveletek (minta):**
- `;
       _oxl.workbooks[1].worksheets[i].name := _kNev;
       _oxl.workbooks[1].worksheets[I].select;
       _range := _oxl.range[`
- `];
       _range.select;
       _oxl.Activewindow.FreezePanes := True;
     end;
   _oxl.workbooks[1].worksheets[9].name :=`
- `;

  _oxl.workbooks[1].worksheets[9].select;
  _range := _oxl.range[`
- `];
  _range.select;
  _oxl.Activewindow.FreezePanes := True;

  _oxl.workbooks[1].worksheets[10].name :=`
- `;

  _oxl.workbooks[1].worksheets[10].select;
  _range := _oxl.range[`

## Felhasználói üzenetek (üzleti szabály-jelek)
- AZ ADATOKAT NEM SIKERÜLT LETÖLTENI - MUNKA NEM LEHETSÉGES
- NEM SIKERÜLT EGYETLEN ADATFILET SEM LETÖLTENI A SZERVERRŐL
- NINCS INTERNETKAPCSOLAT !
- NEM TALÁLOM A WININET.DLL KÖNYVTÁRAT
- Nem érem el a Szervert !
- Nem sikerült csatlakozni a szerverhez !
- Nem sikerült belépni a pillanatnyi-készlet-könyvtárába !
- NEM TALÁLTAM PILLANATNYI KÉSZLETEKET

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
