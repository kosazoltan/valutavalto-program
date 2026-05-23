# Legacy modul (SZERVER): BEERKCTRL

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/beerkctrl/debug/unit2.pas` (7109 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/beerkctrl/makedll/missctrl.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`tegnapcontrol`

## DFM form(ok) / képernyő
`TForm1`, `TForm2`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · Panel1 · Form2 · ELLEN · NEM  · TOV

## Eljárások / függvények (.pas)
`Button1Click`, `FormActivate`, `SearchMiss`, `KilepoTimer`, `PenztarnevBeolvasas`, `Date2str`, `Nulele`, `TOVABBGOMBClick`, `TForm2.FormActivate`, `TForm2.SearchMiss`, `TForm2.Date2str`, `TForm2.Button1Click`, `TForm2.KilepoTimer`, `TForm2.Nulele`, `TForm2.PenztarnevBeolvasas`, `TForm2.TOVABBGOMBClick`

## Érintett adatbázis-táblák
`IRODAK`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `SELECT * FROM IRODAK ORDER BY UZLET`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
