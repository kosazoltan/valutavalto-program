# Legacy modul (SZERVER-FEJLESZT): PTTRFEE

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/fejleszt/pttrfee/unit1.pas` (17610 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/fejleszt/pttrfee/pttrfee.dpr`
> Alrendszer: **SZERVER-FEJLESZT** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`

**Feliratok/gombok (Caption):** Form1 · HAVI TRANZAKCI · dekanySoft · KIL

## Eljárások / függvények (.pas)
`HOOKEGOMBClick`, `IrodakBeolvasasa`, `FormActivate`, `TranzdijBeolvasasa`, `MakeExcel`, `Nulele`, `Scanetar`, `ScanPenztar`, `SCantpt`, `KILEPOTIMERTimer`, `KILEPESGOMBClick`, `EVCOMBOChange`, `Kezelesidijbeolvasasa`, `TForm1.FormActivate`, `TForm1.HOOKEGOMBClick`, `TForm1.KezelesidijBeolvasasa`, `TForm1.TranzdijBeolvasasa`, `TForm1.Scanetar`, `TForm1.ScanPenztar`, `TForm1.IrodakBeolvasasa`, `TForm1.Nulele`, `TForm1.MakeExcel`, `TForm1.SCantpt`, `TForm1.KILEPOTIMERTimer`, `TForm1.KILEPESGOMBClick`, `TForm1.EVCOMBOChange`

## Érintett adatbázis-táblák
`IRODAK`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `SELECT * FROM IRODAK`
- `];
  _range.select;
  _range.mergecells  := true;
  _range.horizontalalignment := -4108;

  _range.Font.Name   :=`
- `];
  _range.select;
  _range.Font.Name   :=`
- `+inttostr(6+_tenypenztardarab)];
  _range.Select;
  _range.Font.name :=`
- `+inttostr(6+_tenypenztardarab)];
  _range.Select;
  _range.HorizontalAlignment := -4108;

  _range := _oxl.range[`
- `+inttostr(6+_tenypenztardarab)];
  _range.Select;
  _range.numberformat :=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NINCSENEK ADATOK A KÉRT HÓNAPRÓL !

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
