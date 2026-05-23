# Legacy modul: BIZODISP

> Forrás (primer): `Anti/VALUTA/DLL/BIZODISP/MAKEDLL/Unit2.pas` (45933 karakter) · library: `DLL/BIZODISP/MAKEDLL/Bizodisp.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`bizonylattallozo`

## DFM form(ok) / képernyő
`TBIZONYLATDISP`, `TForm3`

**Feliratok/gombok (Caption):** BIZONYLATDISP · Label2 · NAV NYUGTA · Blokk fejek · BIZONYLAT · BLOKK (FT) · KEZ-DIJ · VALUTA · FORINT · TIZ-MILLI · ENGED · Blokkt · 2013 szeptember 23 · El · Panel2 · Vissza a men · Bizonylatok sz · A H · CSAK A V · OKM · Jogi szem · Telephely c · Okiratsz · Megbizott beosz · Ezt a napot k

## Eljárások / függvények (.pas)
`FormActivate`, `VISSZAGOMBClick`, `FejrekordValtozott`, `StornoKijelzo`, `Ugyfelkijelzo`, `MindentLezar`, `SegedAdatBazisokatLezar`, `MainapDisplay`, `Setcondi`, `Ujranyomtatas`, `DatumKiertekeles`, `Nulele`, `Panel6Click`, `BlokktipusKijelzo`, `Panel7Click`, `NAPTARChange`, `BLOKKFEJRACSKeyUp`, `BLOKKFEJRACSCellClick`, `BLOKKFEJRACSDblClick`, `PenztarBetoltes`, `PenztarKijelzo`, `ProsnevKijelzo`, `TulajPanelsClear`, `ScanPenztar`, `Button1Click`, `BitBtn1Click`, `EGESZHONAPClick`, `ValutaParancs`, `VTempKitoltes`, `INDOKEDITKeyDown`

## Érintett adatbázis-táblák
`BLOKKFEJ`, `JOGISZEMELY`, `PARTNERPARA`, `PENZTAR`, `UGYFEL`, `UJTULAJOK`, `VTEMP`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `WHERE (DATUM=`
- `WHERE`
- `WHERE BIZONYLATSZAM=`
- `SELECT * FROM UGYFEL WHERE UGYFELSZAM=`
- `SELECT * FROM UGYFEL`
- `WHERE UGYFELSZAM=`
- `SELECT * FROM UJTULAJOK`
- `SELECT * FROM BLOKKFEJ`
- `SELECT * FROM PENZTAR`
- `DELETE FROM VTEMP`
- `INSERT INTO VTEMP (VALUTANEM,ARFOLYAM,ELSZAMOLASIARFOLYAM,`

## Felhasználói üzenetek (üzleti szabály-jelek)
- Nincs adat a kért hónapról
- A kért napról nincsenek adataim az adott feltételek mellett!
- A kért napról nincsenek adataim !

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
