# Legacy modul (SZERVER): WUNIDISP

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/wunidisp/debug/unit2.pas` (12034 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/wunidisp/makedll/wudisp.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`wudisplayrutin`

## DFM form(ok) / képernyő
`TForm1`, `TWUNIDISPLAY`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · WUNIDISPLAY · WESTERN UNION  · 2009 SZEPTEMBER 1 - 30 · TRANZAKCI · WESTERN UNION $ · WESTERN UNION Ft · BEV · NYIT · KIAD · SZERVER MEN · Intercash/Innova · Intercash/innova · MASIK ID · AZ EXPRESSZ  · 123 400 · 582 000 · 250 000 · 254 000 · 123 500 600 · 150 000 000 · 1 250 000 · 15 480

## Eljárások / függvények (.pas)
`QUITGOMBClick`, `FormActivate`, `ParameterBeolvasas`, `ForintForm`, `ScanBetu`, `ScanKorzet`, `MasAdatokGombClick`, `MasEgysegGombClick`, `MasIdoszakGombClick`, `TablaDisplay`, `KilepoTimer`, `ZALOGPLUSBOXClick`, `TWUNIDISPLAY.FormActivate`, `TWunidisplay.TablaDisplay`, `TWunidisplay.ForintForm`, `TWuniDisplay.ParameterBeolvasas`, `TWuniDisplay.ScanKorzet`, `TWuniDisplay.ScanBetu`, `TWuniDisplay.MASADATOKGOMBClick`, `TWuniDisplay.MASEGYSEGGOMBClick`, `TWuniDisplay.MASIDOSZAKGOMBClick`, `TWuniDisplay.QUITGOMBClick`, `TWuniDisplay.KILEPOTimer`, `TWuniDisplay.ZALOGPLUSBOXClick`

## Érintett adatbázis-táblák
`ADATATADO`, `IDOSZAK`, `WUNIGYUJTO`

**SQL-műveletek (minta):**
- `SELECT * FROM WUNIGYUJTO`
- `WHERE`
- `SELECT * FROM ADATATADO`
- `SELECT * FROM IDOSZAK`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
