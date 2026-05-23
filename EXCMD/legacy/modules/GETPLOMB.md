# Legacy modul: GETPLOMB

> Forrás (primer): `Anti/VALUTA/DLL/GETPLOMB/MAKEDLL/Unit2.pas` (6839 karakter) · library: `DLL/GETPLOMB/MAKEDLL/Getplomb.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`getplombarutin`

## DFM form(ok) / képernyő
`TGETPLOMBASZAM`

**Feliratok/gombok (Caption):** GETPLOMBASZAM · SZ · PLOMBASZ · MEGJEGYZ · TARSSZAMPANEL · TARSNEVPANEL

## Eljárások / függvények (.pas)
`FormActivate`, `MEGSEMGOMBClick`, `SZALLNEVEDITKeyDown`, `PLOMBAEDITKeyDown`, `MEGJEGYZESEDITKeyDown`, `KONYVELHETOGOMBClick`, `SZALLNEVEDITEnter`, `SZALLNEVEDITExit`, `Penztarbeolvasas`, `EmptyControl`, `TGETPLOMBASZAM.FormActivate`, `TGETPLOMBASZAM.MEGSEMGOMBClick`, `TGETPLOMBASZAM.SZALLNEVEDITKeyDown`, `TGETPLOMBASZAM.PLOMBAEDITKeyDown`, `TGETPLOMBASZAM.MEGJEGYZESEDITKeyDown`, `TGETPLOMBASZAM.KONYVELHETOGOMBClick`, `TGETPLOMBASZAM.SZALLNEVEDITEnter`, `TGETPLOMBASZAM.SZALLNEVEDITExit`, `TGetPlombaszam.Penztarbeolvasas`, `TGetPlombaszam.EmptyControl`

## Érintett adatbázis-táblák
`VTEMP`

**SQL-műveletek (minta):**
- `UPDATE VTEMP SET SZALLITONEV=`
- `SELECT * FROM VTEMP`
- `INSERT INTO VTEMP (MENET)`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
