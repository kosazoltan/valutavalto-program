# Legacy modul: NAVZARO

> Forrás (primer): `Anti/VALUTA/DLL/NAVZARO/MAKEDLL/Unit2.pas` (24267 karakter) · library: `DLL/NAVZARO/MAKEDLL/Navzaro.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`navzarocontrol`

## DFM form(ok) / képernyő
`TForm2`

**Feliratok/gombok (Caption):** Form2 · forint fi · 500 000 000 Ft · FORINT RENDBEN · A NAV-OS P · A C · TOV · A NAV-OS FORINT FI · A P · E-MAIL K

## Eljárások / függvények (.pas)
`FormActivate`, `ZFTPANELClick`, `HIDEEDITEnter`, `HIDEEDITExit`, `HIDEEDITKeyDown`, `FtForm`, `ZFTRENDBENGOMBClick`, `NAVOKEGOMBClick`, `PIROSTOVABBGOMBClick`, `MakeXML`, `XMLBemasolas`, `TitkosEmail`, `Angolra`, `KozepreIr`, `HutoGb`, `GetEmailcimek`, `Nulele`, `ValutaParancs`, `Pillnyomtatas`, `Kezdijnyomtatas`, `Blokkfocimiro`, `TextKiiro`, `FormKiir`, `TForm2.FormActivate`, `TForm2.ZFTPANELClick`, `TForm2.HIDEEDITEnter`, `TForm2.HIDEEDITExit`, `TForm2.HIDEEDITKeyDown`, `TForm2.FtForm`, `TForm2.ZFTRENDBENGOMBClick`

## Érintett adatbázis-táblák
`ARFOLYAM`, `CIMINI`, `HARDWARE`, `MEDIA`, `NAPIKEZELESIDIJ`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM CIMINI`
- `WHERE (VALUTANEM=`
- `SELECT * FROM NAPIKEZELESIDIJ WHERE DATUM=`
- `DELETE FROM MEDIA`
- `INSERT INTO MEDIA (REMOTEDIR,REMOTEFILE,LOCALPATH)`
- `SELECT * FROM ARFOLYAM`
- `WHERE ZARO<>0`
- `SELECT * FROM NAPIKEZELESIDIJ`
- `WHERE DATUM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- LEGALÁBB 20 KARAKTER KELL A MEGJEGYZÉSBEN
- AZ E-MAILEKET SIKERESEN ELKÜLDTEM

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
