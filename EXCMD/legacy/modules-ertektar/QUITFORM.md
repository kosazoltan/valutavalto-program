# Legacy modul (ÉRTÉKTÁR): QUITFORM

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/quitform/debug/unit2.pas` (10166 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/quitform/makedll/quitform.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`quitrutin`

## DFM form(ok) / képernyő
`TForm1`, `TQUITFORM`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · QUITFORM · KIL · HOLNAP NYITVA LESZ A P · IGEN, NYITVA  LESZ · NEM, Z · BIZTOS, HOGY KIL

## Eljárások / függvények (.pas)
`FormActivate`, `NyilatkozatNyomtato`, `EzSzombat`, `NyitvaVagy`, `NONQUITGOMBClick`, `QUITGOMBClick`, `QUITTIMERTimer`, `NYITVAGOMBClick`, `ZARVAGOMBClick`, `Ezpentek`, `GetCegNev`, `KozepreIr`, `StrtoHunDate`, `TQUITFORM.FormActivate`, `TQuitForm.Nyitvavagy`, `TQUITFORM.NONQUITGOMBClick`, `TQUITFORM.QUITGOMBClick`, `TQUITFORM.QUITTIMERTimer`, `TQuitForm.Ezpentek`, `TQuitform.EzSzombat`, `TQuitForm.NyilatkozatNyomtato`, `TQuitForm.KozepreIr`, `TQUITFORM.NYITVAGOMBClick`, `TQUITFORM.ZARVAGOMBClick`, `TQuitForm.StrtoHunDate`, `TQuitForm.GetCegNev`

## Érintett adatbázis-táblák
`HARDWARE`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
