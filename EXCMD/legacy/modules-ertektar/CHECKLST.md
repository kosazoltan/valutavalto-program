# Legacy modul (ÉRTÉKTÁR): CHECKLST

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/checklst/debug/unit2.pas` (13644 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/checklst/makedll/checklst.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`checkcontrol`

## DFM form(ok) / képernyő
`TForm1`, `TTASKCTRL`

**Feliratok/gombok (Caption):** Form1 · Button1 · KIL · VISSZA A F · 2013.11.05 · 2013.02.22 · el · NYOMTAT · VISSZA A MEN

## Eljárások / függvények (.pas)
`Sorjeloles`, `Oszlopixelo`, `ChangeCheckJel`, `FormActivate`, `Edit1MouseMove`, `Edit1Exit`, `VISSZAGOMBClick`, `SuperControl`, `NAPTARChange`, `Label5Click`, `ELOZOHOClick`, `KOVETKEZOHOClick`, `NAPTARDblClick`, `Gepadatok`, `Edit1Click`, `ROGZITOGOMBClick`, `NYOMTATOGOMBClick`, `KILEPOTimer`, `Hundatetostr`, `Nulele`, `checkcontrol`, `supervisorjelszo`, `TTASKCTRL.FormActivate`, `TTASKCTRL.Supercontrol`, `TTASKCTRL.Edit1MouseMove`, `TTASKCTRL.Sorjeloles`, `TTASKCTRL.Edit1Exit`, `TTASKCTRL.VISSZAGOMBClick`, `TTASKCTRL.NAPTARChange`, `TTASKCTRL.Label5Click`

## Érintett adatbázis-táblák
`HARDWARE`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`

## Felhasználói üzenetek (üzleti szabály-jelek)
- A KÉRT NAPRÓL NINCS CHECKLISTA
- A NAPI CHECKFILE MÁR RÖGZITVE VAN !
- A CSEKKLISTÁT SIKERESEN RÖGZITETTEM

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
