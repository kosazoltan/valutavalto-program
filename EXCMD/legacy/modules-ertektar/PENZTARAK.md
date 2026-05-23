# Legacy modul (ÉRTÉKTÁR): PENZTARAK **[ÉRTÉKTÁR-EGYEDI — nincs VALUTA megfelelő]**

> Forrás (primer): `Anti/SZERVER/_extracted/ERTEKTAR/etdll/penztarak/debug/unit2.pas` (95210 karakter) · library: `Anti/SZERVER/_extracted/ERTEKTAR/etdll/penztarak/makedll/ptarak.dpr`
> Alrendszer: **ERTEKTAR** (értéktár) — a SZERVER/_extracted/ERTEKTAR/etdll-ből.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`penztarakrutin`

## DFM form(ok) / képernyő
`TForm1`, `TPILLKESZFORM`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · Pillanatnyi k · VALUTA · ELAD · 325,45 · 330,00 · AUD · AV2PAN · AE2PAN · BAM · AV19PAN · AE19PAN · PLN · AV4PAN · AE4PAN · BRL · AV5PAN · AE5PAN · CAD · AV6PAN · AE6PAN · CHF · AV7PAN

## Eljárások / függvények (.pas)
`FormActivate`, `AdatDisplay`, `AdatFrissites`, `AdatFrissitoGombClick`, `AdatNullazo`, `AdatSummazas`, `AktaParancs`, `AktArfFeltoltes`, `AlapAdatBeolvasas`, `ArfolyamDisplay`, `ArfolyamTombClear`, `ArfolyamTombFeltoltes`, `BitBtn1Click`, `Button5Click`, `Button9Click`, `CsakEladasClick`, `CsakVasarClick`, `KeszForgtombFeltoltes`, `PkDekodolo`, `EgyPenztarDisplay`, `F1GombClick`, `F2GombClick`, `F3GombClick`, `FormCreate`, `FTPSzerverbeBelep`, `FrissitoTimerTimer`, `GrafikonDisplay`, `GrafikonGombClick`, `GrafikonPanelExit`, `IrodaAdatBeolvasas`

## Érintett adatbázis-táblák
`AKTARF`, `ARFOLYAM`, `HARDWARE`, `IRODAK`, `PENZTAR`

**SQL-műveletek (minta):**
- `SELECT * FROM IRODAK`
- `WHERE (CLOSED<>`
- `SELECT * FROM ARFOLYAM WHERE VALUTANEM=`
- `SELECT * FROM HARDWARE`
- `SELECT * FROM PENZTAR`
- `DELETE FROM AKTARF`
- `INSERT INTO AKTARF (VALUTANEM,VETELIARFOLYAM,ELADASIARFOLYAM,`
- `SELECT * FROM AKTARF`
- `WHERE VALUTANEM<>`
- `UPDATE ARFOLYAM SET ELSZAMOLASIARFOLYAM=`
- `WHERE VALUTANEM=`
- `SELECT * FROM ARFOLYAM`

## Felhasználói üzenetek (üzleti szabály-jelek)
- NEM SIKERÜLT AZ MNB ÁRFOLYAMOK LETÖLTÉSE
- NINCS A SZERVEREN MAI NAPI MNB ÁRFOLYAM RÖGZITVE
- NINCSENEK ÁRFOLYAMOK AZ ADATOKBAN

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
