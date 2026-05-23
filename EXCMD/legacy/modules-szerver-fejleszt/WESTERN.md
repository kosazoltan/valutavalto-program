# Legacy modul (SZERVER-FEJLESZT): WESTERN

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/western/unit1.pas` (43009 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/western/western.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · Western Union havi forgalmi adatai. · dekanySoft · START · KIL

## Eljárások / függvények (.pas)
`KILEPGOMBClick`, `STARTGOMBClick`, `ErtektarWuData`, `ExcelKill`, `MakeExcel`, `SetPenztarsor`, `AdatUrito`, `HibaWrite`, `ElsejePotlasa`, `Korzetbesorolas`, `EgyNapiAdatFeltoltes`, `EgykorzetNapja`, `CegosszesenSor`, `Napifejlec`, `HaviWesternTablo`, `PenztarWuData`, `Vastagkeret`, `Vekonykeret`, `Getcegss`, `Getkorzetss`, `Nulele`, `ScanPenztar`, `ScanKorzet`, `FormActivate`, `EVCOMBOChange`, `TForm1.FormActivate`, `TForm1.STARTGOMBClick`, `TForm1.HaviWesternTablo`, `TForm1.SetPenztarsor`, `TForm1.KorzetbeSorolas`

## Érintett adatbázis-táblák
`IRODAK`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `WHERE STORNO=1`
- `SELECT * FROM IRODAK`
- `WHERE (WESTERNUNION=1) AND (CLOSED=`
- `;

  _oxl.worksheets[_aktnap].select;
  _range := _oxl.range[`
- `];
  _range.Select;

  // ------------------- KERETEZES ---------------------------------------------

  _ks :=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- A KÉRT HÓNAP A JÖVŐBEN LESZ

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
