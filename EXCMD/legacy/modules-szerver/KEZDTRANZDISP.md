# Legacy modul (SZERVER): KEZDTRANZDISP

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/kezdtranzdisp/debug/unit2.pas` (19844 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/kezdtranzdisp/makedll/kdtrdisp.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`kezdtranzdisplay`

## DFM form(ok) / képernyő
`TForm1`, `TForm2`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · Form2 · UZENOPANEL · VISSZA A F · A KEZEL

## Eljárások / függvények (.pas)
`PenztarParaBeolvasas`, `Korzetbeiro`, `MakeExcel`, `FormActivate`, `KilepoTimer`, `Keret`, `VisszaGombClick`, `GetKorzetnev`, `ScanKorzet`, `TForm2.FormActivate`, `TForm2.MakeExcel`, `TForm2.GetKorzetnev`, `TForm2.ScanKorzet`, `TForm2.PenztarParaBeolvasas`, `TForm2.Keret`, `TForm2.KILEPOTimer`, `TForm2.VISSZAGOMBClick`, `TForm2.Korzetbeiro`

## Érintett adatbázis-táblák
`IDOSZAK`, `IRODAK`

**SQL-műveletek (minta):**
- `SELECT * FROM IDOSZAK`
- `SELECT * FROM`
- `WHERE PENZTAR<151`
- `SELECT * FROM IRODAK ORDER BY UZLET`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NINCS HAVI TÁBLA
- NINCS EXPRESSZ HAVI TÁBLA

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
