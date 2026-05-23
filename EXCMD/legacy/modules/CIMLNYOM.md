# Legacy modul: CIMLNYOM

> Forrás (primer): `Anti/VALUTA/DLL/CIMLNYOM/MAKEDLL/Unit2.pas` (18997 karakter) · library: `DLL/CIMLNYOM/MAKEDLL/CimlNyom.dpr`
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`cimletnyomtatorutin`

## DFM form(ok) / képernyő
`TCIMLETNYOM`

**Feliratok/gombok (Caption):** CIMLETNYOM · NYOMAT · MINDEN KIJEL · KIL · Valutav · Kezel · Western Union c · AFA cimletek nyomtat · Foglal · Elektromos keresked · NYOMTAT

## Eljárások / függvények (.pas)
`KILEPOTimer`, `FormActivate`, `ALLMARKGOMBClick`, `STARTGOMBClick`, `AlapadatBeolvasas`, `SetMarkers`, `AdatNullazas`, `DVonalHuzo`, `VonalHuzo`, `Kozepreir`, `Ujsor`, `CimletTypeRegister`, `Adatbegyujtes`, `StartNyomtatas`, `Nulele`, `Getdnev`, `getcimletes`, `negyes`, `Tizenegy`, `EgyTemaCImletNyomtatasa`, `EXITGOMBClick`, `BitBtn1Click`, `VegNyomtatas`, `TCIMLETNYOM.FormActivate`, `TCIMLETNYOM.Alapadatbeolvasas`, `TCIMLETNYOM.STARTGOMBClick`, `TCimletnyom.VegNyomtatas`, `TCIMLETNYOM.EgyTemaCImletNyomtatasa`, `TCIMLETNYOM.getcimletes`, `TCIMLETNYOM.negyes`

## Érintett adatbázis-táblák
`CIMINI`, `FOGLALOKESZLET`, `HARDWARE`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `SELECT * FROM FOGLALOKESZLET`
- `UPDATE HARDWARE SET MENETSZAM=`
- `SELECT * FROM CIMINI`
- `WHERE CIMLETTYPE=`
- `SELECT * FROM`
- `WHERE DATUM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NEM VOLT KIJELÖLT CIMLETEZÉS !

## Megfeleltetés a jelenlegi programmal
_(TBD — a modul-térkép `EXCMD/legacy/00-VALUTA-modul-terkep.md` alapján; gap-jelölt, ha a fenti logika/üzenet a jelenlegi programból hiányzik.)_
