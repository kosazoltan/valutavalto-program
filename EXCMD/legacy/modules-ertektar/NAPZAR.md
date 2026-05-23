# Legacy modul (ÉRTÉKTÁR): NAPZAR

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/napzar/debug/unit2.pas` (33324 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/napzar/makedll/napzar.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`napzarrutin`

## DFM form(ok) / képernyő
`TForm1`, `TNAPZARFORM`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · NAPI P · 2017.05.22 · Kezel · W.U. c · V1 · V2 · V3 · V4 · Napi z · Ellen · E-kereskedelem c · A NAPI Z

## Eljárások / függvények (.pas)
`FormActivate`, `HaviGyujtokbeMasolas`, `InditoTimer`, `ValutaParancs`, `ValdataParancs`, `ZOkeGombClick`, `BFCopy`, `BTCopy`, `CIMTCopy`, `NarfCopy`, `WuniCopy`, `WzarCopy`, `EdatCopy`, `EkerCopy`, `KDatCopy`, `KezdijCopy`, `CimtipRogzito`, `Nulele`, `checkcontrol`, `TNAPZARFORM.FormActivate`, `TNAPZARFORM.INDITOTimer`, `TNAPZARFORM.HavigyujtokbeMasolas`, `TNAPZARFORM.ZOKEGOMBClick`, `TNAPZARFORM.CimtipRogzito`, `TNAPZARFORM.ValutaParancs`, `TNAPZARFORM.ValdataParancs`, `TNAPZARFORM.Nulele`, `TNapzarForm.BfCopy`, `TNapzarForm.BtCopy`, `TNapzarForm.cIMTCopy`

## Érintett adatbázis-táblák
`ARFOLYAM`, `BLOKKFEJ`, `BLOKKTETEL`, `CIMINI`, `EKERDATA`, `EKERESKEDELEM`, `HARDWARE`, `HRKNAPLO`, `KEZDIJ`, `KEZDIJDATA`, `VTEMP`, `WUAFAFORG`, `WZARO`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM VTEMP`
- `SELECT * FROM HRKNAPLO WHERE DATUM=`
- `UPDATE HARDWARE SET LEZARTNAP=`
- `UPDATE HARDWARE SET MENETSZAM=`
- `SELECT * FROM BLOKKFEJ`
- `INSERT INTO`
- `DELETE FROM BLOKKFEJ`
- `SELECT * FROM BLOKKTETEL`
- `DELETE FROM BLOKKTETEL`
- `DELETE FROM`
- `WHERE DATUM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NINCS BELÉPÉSI DÁTUM A HARDWARE-BEN
- HIÁNYZIK VAGY ELTÉR AZ ESTI PÉNZTÁR CIMLETEZÉSE
- Nincs, vagy nem egyezik a kezelési díj címletezése
- Nincs, vagy nemegyezik a  Western Union cimletezés 
- Az ÁFA-pénztár nincs cimletezve
- Az e-kereskedelem nincs cimletezve

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
