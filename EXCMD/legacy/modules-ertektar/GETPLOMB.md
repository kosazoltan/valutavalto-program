# Legacy modul (ÉRTÉKTÁR): GETPLOMB

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/getplomb/debug/unit2.pas` (6839 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/getplomb/makedll/getplomb.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`getplombarutin`

## DFM form(ok) / képernyő
`TForm1`, `TGETPLOMBASZAM`

**Feliratok/gombok (Caption):** Form1 · VISSZAT · INDIT · KILEP · Panel1 · GETPLOMBASZAM · SZ · PLOMBASZ · MEGJEGYZ · TARSSZAMPANEL · TARSNEVPANEL

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
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
