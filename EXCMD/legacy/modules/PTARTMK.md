# Legacy modul: PTARTMK

> Forrás (primer): `Anti/VALUTA/DLL/PTARTMK/MAKEDLL/Unit2.pas` (15087 karakter) · library: `DLL/PTARTMK/MAKEDLL/ptartmk.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`penztartmkrutin`

## DFM form(ok) / képernyő
`TPENZTARTMKFORM`

**Feliratok/gombok (Caption):** PENZTARTMKFORM ·  VISSZA A F · TELEFONSZ · EGY P · RENDBEN · ADATOK M · BIZTOSAN T

## Eljárások / függvények (.pas)
`AdatFeliras`, `Adatbeolvasas`, `PenztarModositas`, `MegsemgombClick`, `EscapeGombClick`, `FormActivate`, `PenztarszamEditEnter`, `PenztarszamEditExit`, `PenztarszamEditKeyDow`, `PenztarTorlesGombClick`, `RendbenGombClick`, `TorolNemGombClick`, `TorolIgenGombClick`, `UjpenztarGombClick`, `inditotimerTimer`, `PenztarNevEditKeyDown`, `PenztarCimEditKeyDown`, `TelefonEditKeyDown`, `ValutaParancs`, `PenztarNyitas`, `PenztarModify`, `Vanilyenszam`, `PENZTARRACSDblClick`, `PENZTARRACSKeyDown`, `supervisorjelszo`, `TPENZTARTMKFORM.FormActivate`, `TPenztarTMKForm.InditoTimerTimer`, `TPenztarTmkForm.PenztarModositas`, `TpenztarTMKForm.PenztarModify`, `TPENZTARTMKFORM.PENZTARNEVEDITKeyDown`

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
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
