# Legacy modul (ÉRTÉKTÁR): NIFVAL **[ÉRTÉKTÁR-EGYEDI — nincs VALUTA megfelelő]**

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/nifval/debug/unit2.pas` (14163 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/nifval/makedll/nifval.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`nifvalasztorutin`

## DFM form(ok) / képernyő
`TForm1`, `TNIFFILEVALASZTO`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · VISSZA A F · FRISSIT

## Eljárások / függvények (.pas)
`EscapeGombClick`, `FormActivate`, `FrissitoGombClick`, `FTPszerverbeBelep`, `GetPenztarPara`, `KilepoTimerTimer`, `NifetValasztott`, `NifValasztas`, `ValasztoListaKeyDown`, `ValasztoListaDblClick`, `ValutaParancs`, `TNIFFILEVALASZTO.FormActivate`, `TNifFileValaszto.NifValasztas`, `TNifFileValaszto.EscapeGombClick`, `TNIFFILEVALASZTO.VALASZTOLISTAKeyDown`, `TNIfFileValaszto.NifetValasztott`, `TNIFFILEVALASZTO.VALASZTOLISTADblClick`, `TNIFFILEVALASZTO.FRISSITOGOMBClick`, `TNifFileValaszto.KilepoTimerTimer`, `TNifFileValaszto.GetPenztarPara`, `TNifFileValaszto.ValutaParancs`, `TnIFfILEvALASZTO.FTPszerverbeBelep`

## Érintett adatbázis-táblák
`HARDWARE`, `MEDIA`, `PENZTAR`, `VTEMP`

**SQL-műveletek (minta):**
- `DELETE FROM MEDIA`
- `INSERT INTO MEDIA (STTFILE)`
- `SELECT * FROM VTEMP`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NEM TALÁLOM A WININET.DLL KÖNYVTÁRAT
- A KÖZPONTI SZERVER NEM ÉRHETŐ EL

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
