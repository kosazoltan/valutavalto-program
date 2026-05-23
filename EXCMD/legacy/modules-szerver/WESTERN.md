# Legacy modul (SZERVER): WESTERN

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/western/debug/unit2.pas` (44680 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/western/makedll/westforg.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`westernforgalom`

## DFM form(ok) / képernyő
`TForm1`, `TForm2`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · Form2 · Western Union havi forgalmi adatai · STARTGOMB · KIL

## Eljárások / függvények (.pas)
`AdatUrito`, `CegosszesenSor`, `ElsejePotlasa`, `ExcelKill`, `EgyNapiAdatFeltoltes`, `EgykorzetNapja`, `ErtektarWuData`, `EvComboChange`, `FormActivate`, `HaviWesternTablo`, `HibaWrite`, `KilepGombClick`, `Korzetbesorolas`, `MakeExcel`, `Napifejlec`, `PenztarWuData`, `SetPenztarsor`, `StartGombClick`, `Vastagkeret`, `Vekonykeret`, `Getcegss`, `Getkorzetss`, `Nulele`, `ScanPenztar`, `ScanKorzet`, `TForm2.FormActivate`, `TForm2.StartGombClick`, `TForm2.HaviWesternTablo`, `TForm2.PenztarWUdata`, `TForm2.ErtektarWUdata`

## Érintett adatbázis-táblák
`IRODAK`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `WHERE STORNO=1`
- `SELECT * FROM IRODAK`
- `WHERE (WESTERNUNION=1) AND (CLOSED=`
- `;

  _oxl.WorkSheets[_aktNap].select;
  _range := _oxl.Range[`
- `];
  _range.Select;

  // ------------------- KERETEZES ---------------------------------------------

  _ks :=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- A KÉRT HÓNAP A JÖVŐBEN LESZ

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
