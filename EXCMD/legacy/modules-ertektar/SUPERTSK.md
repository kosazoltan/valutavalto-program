# Legacy modul (ÉRTÉKTÁR): SUPERTSK

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/supertsk/debug/unit2.pas` (3254 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/supertsk/makedll/supertsk.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`supervisorrutin`

## DFM form(ok) / képernyő
`TForm1`, `TSUPERVISORFORM`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · SUPERVISORFORM · SUPERVISOR MEN · LOGFILE KIOLVAS · KIL

## Eljárások / függvények (.pas)
`FormActivate`, `ESCAPEGOMBClick`, `CIMLETSETUPGOMBClick`, `FormCreate`, `LOGFILEGOMBClick`, `AlapadatBeolvasas`, `TSUPERVISORFORM.FormActivate`, `TSUPERVISORFORM.AlapadatBeolvasas`, `TSUPERVISORFORM.ESCAPEGOMBClick`, `TSUPERVISORFORM.CIMLETSETUPGOMBClick`, `TSUPERVISORFORM.FormCreate`, `TSUPERVISORFORM.LOGFILEGOMBClick`

## Érintett adatbázis-táblák
`HARDWARE`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
