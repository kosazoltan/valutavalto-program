# Legacy modul: GETPTAR

> Forrás (primer): `Anti/VALUTA/DLL/GETPTAR/MAKEDLL/Unit2.pas` (11174 karakter) · library: `DLL/GETPTAR/MAKEDLL/GetPTar.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`penztarrutin`

## DFM form(ok) / képernyő
`TPENZTARVALASZTOFORM`

**Feliratok/gombok (Caption):** NEM V · EZT V · SZ · MEGNEVEZ · TELEFONSZ · VISSZA A V

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
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
