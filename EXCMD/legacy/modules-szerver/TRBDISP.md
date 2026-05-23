# Legacy modul (SZERVER): TRBDISP

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/trbdisp/debug/unit2.pas` (6234 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/trbdisp/makedll/trbdisp.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`trbforgdisplayrutin`

## DFM form(ok) / képernyő
`TForm1`, `TTRBDISPLAY`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · TRBDISPLAY · A TRB TRANZAKCI · SZERVER MEN · Valuta · Fogad · Fogadott · OK

## Eljárások / függvények (.pas)
`FormActivate`, `KilepoTimer`, `MasAdatGombClick`, `MasEgysegGombClick`, `MasIdoszakGombClick`, `ParameterBeolvasas`, `QuitGombClick`, `StatuszBeiro`, `TTRBDISPLAY.FormActivate`, `TTRBDisplay.ParameterBeolvasas`, `TTRBDisplay.QuitGombClick`, `TTRBDisplay.MasAdatGombClick`, `TTRBDISPLAY.MasEgysegGombClick`, `TTRBDISPLAY.MasIdoszakGombClick`, `TTRBDisplay.KilepoTimer`, `TtrbDisplay.Statuszbeiro`

## Érintett adatbázis-táblák
`ADATATADO`, `IDOSZAK`, `TRBGYUJTO`

**SQL-műveletek (minta):**
- `SELECT * FROM TRBGYUJTO`
- `SELECT * FROM ADATATADO`
- `SELECT * FROM IDOSZAK`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
