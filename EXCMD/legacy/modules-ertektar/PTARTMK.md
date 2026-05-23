# Legacy modul (ÉRTÉKTÁR): PTARTMK

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/ptartmk/debug/unit2.pas` (15232 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/ptartmk/makedll/ptartmk.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`penztartmkrutin`

## DFM form(ok) / képernyő
`TForm1`, `TPENZTARTMKFORM`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · PENZTARTMKFORM ·  VISSZA A F · TELEFONSZ · EGY P · RENDBEN · ADATOK M · BIZTOSAN T

## Eljárások / függvények (.pas)
`AdatFeliras`, `Adatbeolvasas`, `PenztarModositas`, `MegsemgombClick`, `EscapeGombClick`, `FormActivate`, `PenztarszamEditEnter`, `PenztarszamEditExit`, `PenztarszamEditKeyDow`, `PenztarTorlesGombClick`, `RendbenGombClick`, `TorolNemGombClick`, `TorolIgenGombClick`, `UjpenztarGombClick`, `inditotimerTimer`, `PenztarNevEditKeyDown`, `PenztarCimEditKeyDown`, `TelefonEditKeyDown`, `ValutaParancs`, `PenztarNyitas`, `PenztarModify`, `Vanilyenszam`, `PENZTARRACSDblClick`, `PENZTARRACSKeyDown`, `FormCreate`, `supervisorjelszo`, `TPENZTARTMKFORM.FormActivate`, `TPenztarTMKForm.InditoTimerTimer`, `TPenztarTmkForm.PenztarModositas`, `TpenztarTMKForm.PenztarModify`

## Érintett adatbázis-táblák
`PENZTAR`

**SQL-műveletek (minta):**
- `DELETE FROM PENZTAR WHERE PENZTARKOD=`
- `SELECT * FROM PENZTAR`
- `INSERT INTO PENZTAR (PENZTARKOD,PENZTARNEV,PENZTARCIM,TELEFONSZAM)`
- `UPDATE PENZTAR SET PENZTARNEV=`
- `WHERE PENZTARKOD=`
- `SELECT * FROM PENZTAR WHERE PENZTARKOD=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- SAJÁT PÉNZTÁRAT CSAK SUPERVISOR MÓDOSITHAT
- ÚJ PÉNZTÁRAT CSAK SUPERVISOR VEHET FEL
- Ez a pénztárszám már létezik !
- SAJÁT PÉNZTÁR NEM TÖRÖLHETÖ !
- PÉNZTÁRAT CSAK SUPERVISOR TÖRÖLHET 

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
