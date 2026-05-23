# Legacy modul: NAPZAR

> Forrás (primer): `Anti/VALUTA/DLL/NAPZAR/MAKEDLL/Unit2.pas` (43187 karakter) · library: `DLL/NAPZAR/MAKEDLL/Napzar.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`napzarrutin`

## DFM form(ok) / képernyő
`TNAPZARFORM`

**Feliratok/gombok (Caption):** NAPI P · 2017.05.22 · Kezel · MTCN sz · W.U. c · V1 · V2 · V3 · V4 · V5 · Napi z · Ellen · Foglal · E-Trade c · V7 · A NAPI Z

## Eljárások / függvények (.pas)
`CimtarAtmasolas`, `CimtipRogzito`, `CopyTables`, `DekZarCtrl`, `ForgalomBeolvasas`, `FormActivate`, `HaviGyujtokbeMasolas`, `InditoTimer`, `NyitoMeghatarozas`, `NapiForgalomSzamitas`, `NapzarFeltolt`, `NArfolyamFeliras`, `SetGyujtoFileNevek`, `SetRekordDarab`, `UgyfelNullazo`, `ValutaParancs`, `ValdataParancs`, `ZaroBeolvasas`, `ZdatumsVtempbe`, `ZOkeGombClick`, `UresPenztarControl`, `Nulele`, `Scandnem`, `checkcontrol`, `regeneralorutin`, `TNAPZARFORM.FormActivate`, `TNAPZARFORM.INDITOTimer`, `TNapZarForm.UresPenztarControl`, `TNAPZARFORM.HavigyujtokbeMasolas`, `TNAPZARFORM.SetGyujtoFileNevek`

## Érintett adatbázis-táblák
`ARFOLYAM`, `BLOKKFEJ`, `BLOKKTETEL`, `CIMINI`, `HARDWARE`, `JOGISZEMELY`, `QRPARAMS`, `RDB`, `UGYFEL`, `VTEMP`, `WUMOZGAS`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM VTEMP`
- `DELETE FROM QRPARAMS`
- `INSERT INTO QRPARAMS (NUMBER)`
- `UPDATE HARDWARE SET LEZARTNAP=`
- `SELECT * FROM ARFOLYAM`
- `WHERE VALUTANEM=`
- `DELETE FROM`
- `WHERE DATUM=`
- `INSERT INTO`
- `SELECT r.RDB$FIELD_NAME AS FIELD_NAME,`
- `FROM RDB$RELATION_FIELDS r`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NINCS BELÉPÉSI DÁTUM A HARDWARE-BEN
- KITÖLTETLEN MTCN SZÁM VAN EGY WESTERN-UNION BIZONYLATBAN
- HIÁNYZIK VAGY ELTÉR AZ ESTI PÉNZTÁR CIMLETEZÉSE
- Nincs, vagy nem egyezik a kezelési díj címletezése
- Nincs, vagy nemegyezik a  Western Union cimletezés 
- Az ÁFA-pénztár nincs cimletezve
- A foglalókészlet nincs cimletezve
- Az e-kereskedelem nincs cimletezve
- Az axa-bizotsitó nincs cimletezve
- A moneygram nincs cimletezve

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
