# Legacy modul (SZERVER): PTARKOZOTT

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/ptarkozott/debug/unit2.pas` (6771 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/ptarkozott/makedll/ptkdisp.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`ptkforgdisplayrutin`

## DFM form(ok) / képernyő
`TForm1`, `TPENZTARKOZOTTIDISPLAY`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · PENZTARKOZOTTIDISPLAY · SZERVER MEN · 2008 SZEPTEMBER 23 - 28 · FOGAD · ST

## Eljárások / függvények (.pas)
`FormActivate`, `ParameterBeolvasas`, `QuitGombClick`, `StatuszBeiro`, `MasAdatokGombClick`, `MasEgysegGombClick`, `MasIdoszakGombClick`, `KilepoTimer`, `TPenztarKozottiDisplay.FormActivate`, `TPenztarKozottiDisplay.ParameterBeolvasas`, `TPenztarKozottiDisplay.MasAdatokGombClick`, `TPenztarKozottiDisplay.MasEgysegGombClick`, `TPenztarKozottiDisplay.MasIdoszakGombClick`, `TPenztarKozottiDisplay.QuitGOMBClick`, `TPenztarKozottiDisplay.KilepoTimer`, `TPenztarKozottiDisplay.Statuszbeiro`

## Érintett adatbázis-táblák
`IDOSZAK`, `PENZTARKOZOTT`

**SQL-műveletek (minta):**
- `SELECT * FROM PENZTARKOZOTT`
- `SELECT * FROM IDOSZAK`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
