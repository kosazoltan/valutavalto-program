# Legacy modul (ÉRTÉKTÁR): CIMLNYOM

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/cimlnyom/debug/unit2.pas` (18125 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/cimlnyom/makedll/cimlnyom.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`cimletnyomtatorutin`

## DFM form(ok) / képernyő
`TForm1`, `TCIMLETNYOM`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · CIMLETNYOM · NYOMAT · MINDEN KIJEL · KIL · Valutav · Kezel · Western Union c · AFA cimletek nyomtat · Elektromos keresked

## Eljárások / függvények (.pas)
`KILEPOTimer`, `FormActivate`, `ALLMARKGOMBClick`, `STARTGOMBClick`, `AlapadatBeolvasas`, `AdatNullazas`, `DVonalHuzo`, `VonalHuzo`, `Kozepreir`, `Ujsor`, `CimletTypeRegister`, `Adatbegyujtes`, `StartNyomtatas`, `EvvegiNyomtatas`, `Nulele`, `Getdnev`, `getcimletes`, `negyes`, `Otos`, `Tizenegy`, `EgyTemaCImletNyomtatasa`, `EXITGOMBClick`, `TCIMLETNYOM.FormActivate`, `TCIMLETNYOM.Alapadatbeolvasas`, `TCIMLETNYOM.STARTGOMBClick`, `TCIMLETNYOM.EgyTemaCImletNyomtatasa`, `TCIMLETNYOM.getcimletes`, `TCIMLETNYOM.negyes`, `TCIMLETNYOM.Otos`, `TCIMLETNYOM.Tizenegy`

## Érintett adatbázis-táblák
`CIMINI`, `HARDWARE`

**SQL-műveletek (minta):**
- `SELECT * FROM HARDWARE`
- `UPDATE HARDWARE SET MENETSZAM=`
- `SELECT * FROM CIMINI`
- `WHERE CIMLETTYPE=`
- `SELECT * FROM`
- `WHERE DATUM=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NEM VOLT KIJELÖLT CIMLETEZÉS !

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
