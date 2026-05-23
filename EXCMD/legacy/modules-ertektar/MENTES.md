# Legacy modul (ÉRTÉKTÁR): MENTES

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/mentes/debug/unit2.pas` (8398 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/mentes/makedll/mentes.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`backuprestore`

## DFM form(ok) / képernyő
`TForm1`, `TNAPIMENTES`

**Feliratok/gombok (Caption):** Form1 · MINDEN MENT · KIL · ADATB · ELMENT · ADATMENT · ADATVISSZA

## Eljárások / függvények (.pas)
`FormActivate`, `RemdirCtrlAndSend`, `KILEPOTimer`, `AlapadatBeolvasas`, `WinExecAndWait32`, `FdbMentese`, `TNAPIMENTES.FormActivate`, `Tnapimentes.FdbMentese`, `TNAPIMENTES.KILEPOTimer`, `TNapiMentes.RemdirCtrlAndSend`, `TnapiMentes.AlapadatBeolvasas`, `TNapiMentes.WinExecAndWait32`

## Érintett adatbázis-táblák
`HARDWARE`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NEM TALÁLOM 

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
