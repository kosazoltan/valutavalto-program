# Legacy modul (ÉRTÉKTÁR): HAVIZAR

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/havizar/debug/unit2.pas` (31760 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/havizar/makedll/havizar.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`havizarorutin`

## DFM form(ok) / képernyő
`TForm1`, `THAVIZARAS`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · HAVI Z · HAVIZ · Nyomtat

## Eljárások / függvények (.pas)
`AlapadatBeolvasas`, `NyitoBeolvasas`, `AtadAtvetgyujtes`, `AtadAtvetLista`, `ForgalomLista`, `WuafaNyomtatas`, `PenztarAllas`, `Kezelesidijnyomtatas`, `ScanPtar`, `Ekernyomtatas`, `FormKiir`, `ValDataParancs`, `BLokkfocimiro`, `Startnyomtatas`, `SetHzTabla`, `MakeHzTabla`, `EvComboChange`, `FejlecIras`, `FormActivate`, `HoOkeGombClick`, `Kozepreir`, `MegsemGombClick`, `VonalHuzo`, `ForintForm`, `adatnullazas`, `ArfForm`, `Elokieg`, `Kieg`, `Nulele`, `Scandnem`

## Érintett adatbázis-táblák
`HARDWARE`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `SELECT FEJ.*, TET.*`
- `FROM`
- `WHERE (FEJ.STORNO=1)`
- `SELECT * FROM`
- `DELETE FROM`
- `INSERT INTO`
- `UPDATE`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
