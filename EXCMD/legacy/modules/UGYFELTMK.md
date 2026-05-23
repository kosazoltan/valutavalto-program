# Legacy modul: UGYFELTMK

> Forrás (primer): `Anti/VALUTA/DLL/UGYFELTMK/WUNION/MAKEDLL/Unit2.pas` (88430 karakter) · library: `DLL/UGYFELTMK/MAKEDLL/UGYFTMK.DPR`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`ugyfeltmkrutin`

## DFM form(ok) / képernyő
`TForm2`, `TWESTERNUNIONFORM`

**Feliratok/gombok (Caption):** Form2 · Term · SZ · IR SZ · UTCA- H · LC CARD · TART HELY · OKMTIP · AZONOSIT · EL · LE · VISSZA A MEN · TERM · JOGISZEM · Jogi szem · JOGI SZEM · TELEPHELY CIME · OKIRAT SZ · AD · MB. NEVE · MB BEOSZT · Ell · << · >> · BIZONYLAT

## Eljárások / függvények (.pas)
`BitBtn1Click`, `BizonylatRacsCellClick`, `BizonylatRacsDblClick`, `Bizregiszter`, `BizonylatRacsKeyUp`, `Blokkfocimiro`, `CsakEgynapClick`, `DnemHideEditKeyDown`, `EloHoPanelClick`, `Evhodisplay`, `FormActivate`, `GetAktualkeszlet`, `GetHardware`, `HufPanelClick`, `HufPanelMouseMove`, `ICAtvetGombEnter`, `ICAtvetGombExit`, `ICAtvetGombMouseMove`, `ICnyugta`, `KeszletDisplay`, `KilepesGombClick`, `KovHoPanelClick`, `KozepreIr`, `MaiNapDisplay`, `MegsemGombClick`, `MTCNPanelEnter`, `MTCNPanelExit`, `MTCNPanelKeyDown`, `NaptarChange`, `NapValasztoPanelClick`

## Érintett adatbázis-táblák
`ARFOLYAM`, `HARDWARE`, `PENZTAR`, `VTEMP`, `WUAFAADATOK`, `WUAFACEGEK`, `WUGYFEL`, `WUMOZGAS`, `WUNI`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM WUMOZGAS`
- `SELECT * FROM WUAFACEGEK`
- `WHERE CEGSZAM=`
- `SELECT * FROM WUGYFEL`
- `WHERE UGYFELSZAM=`
- `SELECT * FROM WUAFAADATOK`
- `SELECT * FROM`
- `WHERE DATUM=`
- `SELECT * FROM ARFOLYAM WHERE VALUTANEM=`
- `INSERT INTO WUMOZGAS (FOEGYSEGSZAM,PENZTARSZAM,UGYFELSZAM,SORSZAM,`

## Felhasználói üzenetek (üzleti szabály-jelek)
- A KÉRT HÓNAPRÓL NINCSENEK ADATAIM
- NINCS ENNYI 
- A kezdőnap nagyobb az utolsó napnál

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
