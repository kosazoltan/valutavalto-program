# Legacy modul: WUNION

> Forrás (primer): `Anti/VALUTA/DLL/WUNION/MAKEDLL/Unit2.pas` (88205 karakter) · library: `DLL/WUNION/MAKEDLL/Wunion.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`westernunionrutin`

## DFM form(ok) / képernyő
`TWESTERNUNIONFORM`

**Feliratok/gombok (Caption):** Ell · << · >> · BIZONYLAT · VALUTA · MTCN-SZ · USD · 355 670 888 · 456 400 000 · HUF · BIZONYLAT: · PARTNER NEVE: · UK-234567 · 2013.05.22 · 345 000 000 · USD  · STORNOZOTT BIZONYLAT · Bizonylat sztorn · Teljes h · NAP V · List · Okm · Keresem: · PARTNER P · dekanySoft

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
