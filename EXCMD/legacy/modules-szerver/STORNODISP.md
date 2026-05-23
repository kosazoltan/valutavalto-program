# Legacy modul (SZERVER): STORNODISP

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/stornodisp/debug/unit2.pas` (6666 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/stornodisp/makedll/stornodisp.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`stornodisplayrutin`

## DFM form(ok) / képernyő
`TForm1`, `TSTORNODISPLAY`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · STORNODISPLAY · A STORN · (SZ · SZERVER MEN · Iroda · Id · Bizonylat · Indokl · A BIZONYLAT T · Bizonylatsz · Valuta · Bankjegy · VISSZA · MAS EGYS

## Eljárások / függvények (.pas)
`FormActivate`, `QuitGombClick`, `FejRacsKeyDown`, `visszagombClick`, `TeteltValasztott`, `FEJRACSDblClick`, `KILEPOTimer`, `masadatokgombClick`, `masegyseggombClick`, `masidoszakgombClick`, `TSTORNODISPLAY.FormActivate`, `TSTORNODISPLAY.QUITGOMBClick`, `TSTORNODISPLAY.FEJRACSKeyDown`, `TStornodisplay.TeteltValasztott`, `TSTORNODISPLAY.visszagombClick`, `TSTORNODISPLAY.FEJRACSDblClick`, `TSTORNODISPLAY.KILEPOTimer`, `TSTORNODISPLAY.masadatokgombClick`, `TSTORNODISPLAY.masegyseggombClick`, `TSTORNODISPLAY.masidoszakgombClick`

## Érintett adatbázis-táblák
`STORNOFEJ`, `STORNOTETEL`

**SQL-műveletek (minta):**
- `SELECT * FROM STORNOFEJ`
- `SELECT * FROM STORNOTETEL`
- `WHERE (BIZONYLATSZAM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NEM VOLT STORNÓBIZONYLAT A KÉRT IDÖSZAKBAN

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
