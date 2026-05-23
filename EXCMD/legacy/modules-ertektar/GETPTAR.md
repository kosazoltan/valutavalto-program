# Legacy modul (ÉRTÉKTÁR): GETPTAR

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/getptar/debug/unit2.pas` (11176 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/getptar/makedll/getptar.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`penztarrutin`

## DFM form(ok) / képernyő
`TForm1`, `TPENZTARVALASZTOFORM`

**Feliratok/gombok (Caption):** Form1 · VISSZAT · INDIT · KILEP · Panel1 · NEM V · EZT V · SZ · MEGNEVEZ · TELEFONSZ · VISSZA A V

## Eljárások / függvények (.pas)
`FormActivate`, `PenztarRacsKeyDown`, `PenztarRacsDblClick`, `PtarValCancelGombClick`, `FormCreate`, `UJPENZTARGOMBClick`, `PSZAMEDITEnter`, `PSZAMEDITExit`, `PSZAMEDITKeyDown`, `ujptokegombClick`, `Racsmegnyitas`, `UJPTMEGSEMGOMBClick`, `TRBPTEDITKeyDown`, `TRBPTOKEGOMBClick`, `TRBPTMEGSEMGOMBClick`, `TRBBekeres`, `SelectedtoVtemp`, `TRBPTEDITEnter`, `TRBPTEDITExit`, `supervisorjelszo`, `TPenztarValasztoForm.FormActivate`, `TPenztarValasztoForm.RacsMegnyitas`, `TPenztarValasztoForm.PtarValCancelGombClick`, `TPenztarValasztoForm.PenztarRacsDblClick`, `TPenztarValasztoForm.SelectedtoVtemp`, `TPenztarValasztoForm.PenztarRacsKeyDown`, `TPenztarValasztoForm.FormCreate`, `TPenztarValasztoForm.UJPENZTARGOMBClick`, `TPenztarValasztoForm.PSZAMEDITEnter`, `TPenztarValasztoForm.PSZAMEDITExit`

## Érintett adatbázis-táblák
`PENZTAR`, `VTEMP`

**SQL-műveletek (minta):**
- `SELECT * FROM PENZTAR`
- `WHERE PENZTARKOD<>`
- `SELECT * FROM VTEMP`
- `INSERT INTO VTEMP (PENZTARKOD,TARSPENZTARNEV,TRBPENZTAR)`
- `UPDATE VTEMP SET PENZTARKOD=`
- `SELECT * FROM PENZTAR WHERE PENZTARKOD=`
- `INSERT INTO PENZTAR (PENZTARKOD,PENZTARNEV,PENZTARCIM,TELEFONSZAM)`

## Felhasználói üzenetek (üzleti szabály-jelek)
- ILYEN SZÁMÚ PÉNZTÁR MÁR LÉTEZIK

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
