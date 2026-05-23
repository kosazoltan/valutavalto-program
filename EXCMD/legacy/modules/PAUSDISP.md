# Legacy modul: PAUSDISP

> Forrás (primer): `Anti/VALUTA/DLL/PAUSDISP/MAKEDDLL/Unit2.pas` (6599 karakter) · library: `DLL/PAUSDISP/MAKEDDLL/PausDisp.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`szunetkijelzorutin`

## DFM form(ok) / képernyő
`TSZUNETKIJELZO`

**Feliratok/gombok (Caption):** SZUNETKIJELZO · Sz

## Eljárások / függvények (.pas)
`FormActivate`, `MEGSEMGOMBClick`, `SZUNETGOMBClick`, `Getadatok`, `Nulele`, `TOLORACOMBOChange`, `valutaParancs`, `TSZUNETKIJELZO.FormActivate`, `TSZUNETKIJELZO.MEGSEMGOMBClick`, `TSZUNETKIJELZO.SZUNETGOMBClick`, `TSzunetKijelzo.Nulele`, `TSZUNETKIJELZO.TOLORACOMBOChange`, `TSzunetKijelzo.valutaParancs`, `TSzunetKijelzo.Getadatok`

## Érintett adatbázis-táblák
`HARDWARE`, `PAUSES`

**SQL-műveletek (minta):**
- `INSERT INTO PAUSES (DATUM,TOL,IG,MEGNEVEZES,PENZTAROSNEV,MESSNUM)`
- `SELECT * FROM HARDWARE`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
