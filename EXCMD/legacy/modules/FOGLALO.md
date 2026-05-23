# Legacy modul: FOGLALO

> Forrás (primer): `Anti/VALUTA/DLL/FOGLALO/MAKEDLL/Unit2.pas` (80759 karakter) · library: `DLL/FOGLALO/MAKEDLL/foglalo.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`foglalorutinok`

## DFM form(ok) / képernyő
`TFOGLALO`

**Feliratok/gombok (Caption):** FOGLALO · FOGLAL · RENDBEN · AZ  · VISSZAFIZETEND · BIZONYLATSZ · HAT · RENDELT VALUTA: · KOV · 2021.11.22 · 125.500.450 EUR · B00095 · 250 000 HUF · VALNEM · RENDELVE · A FOGLAL · A HAT · BEFEJEZEM A TRANZAKCI · TRANZAKCI · REGISZTR · anyja neve · ANYJA MEVE: · SZ · OKM · AZONOS

## Eljárások / függvények (.pas)
`FormActivate`, `PenztarBeolvasas`, `ValutanemBetoltes`, `Fomenure`, `EmailekKuldese`, `BebIzIro`, `IgenGombClick`, `NevEditEnter`, `NevEditExit`, `NevEditKeyDown`, `RegUgyfelClick`, `UgyfelRacsKeyDown`, `UgyfelValasztoGombClick`, `UgyfeletValasztott`, `UjugyfelGombClick`, `UjNevOkeClick`, `UjnevquitClick`, `UgyfelRacsDblClick`, `ValaszMegsemGombClick`, `VisszaFizetoProcedura`, `Alairasiro`, `ArfolyamEditExit`, `ArfolyamEditEnter`, `AtvetelGombClick`, `AtvetelGombEnter`, `AtvetelGombExit`, `AtvetelGombMouseMove`, `BizonylateditEnter`, `BizonylateditExit`, `BizonylatFejiro`

## Érintett adatbázis-táblák
`ARFOLYAM`, `FOGLALOK`, `FOGLALOKESZLET`, `HARDWARE`, `MEDIA`, `PENZTAR`, `UGYFEL`, `UTOLSOBLOKKOK`, `VTEMP`

**SQL-műveletek (minta):**
- `DELETE FROM FOGLALOK WHERE (DATUM<`
- `SELECT * FROM PENZTAR`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM ARFOLYAM`
- `WHERE (VALUTANEM<>`
- `SELECT * FROM VTEMP`
- `SELECT * FROM UTOLSOBLOKKOK`
- `INSERT INTO UGYFEL (UGYFELSZAM,NEV,ANYJANEVE,SZULETESIHELY,SZULETESIIDO,`
- `UPDATE UTOLSOBLOKKOK SET UTOLSOUGYFELSZAM=`
- `SELECT * FROM UGYFEL`
- `INSERT INTO FOGLALOK (DATUM,BIZONYLATSZAM,UGYFELSZAM,UGYFELTIPUS,`
- `DELETE FROM MEDIA`

## Felhasználói üzenetek (üzleti szabály-jelek)
- AZ E-MAILEKET SIKERESEN ELKÜLDTEM
- AZ ÜGYFÉL ADATAI ÉRVÉNYTELENEK

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
