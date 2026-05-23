# Legacy modul (SZERVER): KESZLETDISP

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/keszletdisp/debug/unit2.pas` (15011 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/keszletdisp/makedll/keszdisp.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`keszletdisplayrutin`

## DFM form(ok) / képernyő
`TForm1`, `TKESZLETDISPLAY`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · KESZLETDISPLAY · ID · Vizsg · Id · Valuta  · Forint  · IROD · 2020 szeptember 34 -21 · VAL · 20.000 · 10.000 · 5.000 · 2.000 · 1.000 · 500 · 200 · 100 · 50 · 20 · 10 · VISSZA A MEN · 123 245 000 Ft

## Eljárások / függvények (.pas)
`FormActivate`, `KilepoGombClick`, `KilepoTimer`, `Kozepreir`, `MasAdatGombClick`, `MasEGYSEGGombClick`, `MasDATUMGombClick`, `ParameterBeolvasas`, `PostabaTesz`, `PostaGombEnter`, `PostaGombExit`, `PostaGombMouseMove`, `TablaDisplay`, `VonalHuzo`, `ArfFormat`, `FFormat`, `ScanBetu`, `ScanKorzet`, `ZALOGPLUSBOXClick`, `TKESZLETDISPLAY.FormActivate`, `TKeszletdisplay.TablaDisplay`, `TKeszletDisplay.PostabaTesz`, `TKeszletDisplay.VonalHuzo`, `TKeszletDisplay.Kozepreir`, `TKeszletDisplay.FFormat`, `TKeszletDisplay.arFFormat`, `TKESZLETDISPLAY.POSTAGOMBEnter`, `TKESZLETDISPLAY.POSTAGOMBExit`, `TKESZLETDISPLAY.POSTAGOMBMouseMove`, `TKeszletDisplay.ParameterBeolvasas`

## Érintett adatbázis-táblák
`ADATATADO`, `CIMLETGYUJTO`, `IDOSZAK`

**SQL-műveletek (minta):**
- `SELECT * FROM CIMLETGYUJTO`
- `WHERE`
- `SELECT * FROM ADATATADO`
- `SELECT * FROM IDOSZAK`

## Felhasználói üzenetek (üzleti szabály-jelek)
- A KÉSZLETET KITETTEM A POSTÁBA >> KESZLET.TXT << NÉVEN

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
