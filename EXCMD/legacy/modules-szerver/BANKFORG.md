# Legacy modul (SZERVER): BANKFORG

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/bankforg/debug/unit2.pas` (5366 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/bankforg/makedll/bankdisp.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`bankiforgdisplayrutin`

## DFM form(ok) / képernyő
`TForm1`, `TBANKFORGALOMDISPLAY`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · BANKFORGALOMDISPLAY · ID · SZERVER MEN · 2009 SZEPTEMBER 25 - 30 · FELVETT-KP · BEFIZETETT-KP

## Eljárások / függvények (.pas)
`QuitGombClick`, `FormActivate`, `ParameterBeolvasas`, `KilepoTimer`, `MasAdatokGombClick`, `MasEgysegGombClick`, `MasikIdoszakGombClick`, `TBANKFORGALOMDISPLAY.QUITGOMBClick`, `TBANKFORGALOMDISPLAY.FormActivate`, `TBankForgalomDisplay.ParameterBeolvasas`, `TBankForgalomDisplay.KilepoTimer`, `TBANKFORGALOMDISPLAY.MASADATOKGOMBClick`, `TBANKFORGALOMDISPLAY.MASEGYSEGGOMBClick`, `TBANKFORGALOMDISPLAY.MASIKIDOSZAKGOMBClick`

## Érintett adatbázis-táblák
`ADATATADO`, `IDOSZAK`, `SUMBANKFORGALOM`

**SQL-műveletek (minta):**
- `SELECT * FROM SUMBANKFORGALOM`
- `SELECT * FROM ADATATADO`
- `SELECT * FROM IDOSZAK`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
