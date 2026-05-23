# Legacy modul (SZERVER): FORGALOMDISP

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/forgalomdisp/debug/unit2.pas` (9441 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/forgalomdisp/debug/forgdisp.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
_(nincs/üres exports clause)_

## DFM form(ok) / képernyő
`TForm1`, `TFORGDISPLAY`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · Panel1 · FORGDISPLAY · ID · Vizsg · AZ IROD · VA- · LU- · TA · Elsz · (100/Ft) · BANKJEGY · FORINT · VALUTA V · VALUTA ELAD · ... · ..... · 2020 szeptember 12 - 25 · SZERVER MEN · AZ EXPRESSZ 

## Eljárások / függvények (.pas)
`FormActivate`, `KilepoGombClick`, `KilepoTimer`, `MasAdatGombClick`, `MasEgysegGombClick`, `MasDatumGombClick`, `TablaDisplay`, `ZalogPlusBoxClick`, `ScanBetu`, `Scankorzet`, `TFORGDISPLAY.FormActivate`, `TForgDisplay.Tabladisplay`, `TFORGDISPLAY.KILEPOGOMBClick`, `TForgDisplay.ScanBetu`, `TFORGDISPLAY.KILEPOTimer`, `TForgDisplay.MasAdatGombClick`, `TForgDisplay.MasEgysegGombClick`, `TForgDisplay.MasDatumGombClick`, `TForgdisplay.Scankorzet`, `TFORGDISPLAY.ZalogPlusBoxClick`

## Érintett adatbázis-táblák
`ADATATADO`, `FORGALOMGYUJTO`, `IDOSZAK`

**SQL-műveletek (minta):**
- `SELECT * FROM ADATATADO`
- `SELECT * FROM IDOSZAK`
- `SELECT * FROM FORGALOMGYUJTO`
- `WHERE`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
