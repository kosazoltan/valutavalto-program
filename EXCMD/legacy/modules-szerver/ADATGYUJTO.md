# Legacy modul (SZERVER): ADATGYUJTO

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/adatgyujto/debug/unit2.pas` (95468 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/adatgyujto/makedll/legyujto.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`adatlegyujtorutin`

## DFM form(ok) / képernyő
`TForm1`, `TADATLEGYUJTES`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · ADATLEGYUJTES · AZ ADATOK LEGY

## Eljárások / függvények (.pas)
`FormActivate`, `IrodaBetolto`, `Idoszakbeolvasas`, `GetLastdaysRates`, `CimletGyujtes`, `ForgalomGyujtes`, `ForgalomRutin`, `SendingRutin`, `StornoRegisztracio`, `BankGyujtes`, `TRBGyujtes`, `InterPtControl`, `TRBControl`, `WuniNullazas`, `WuniForgalomGyujtes`, `GetWuniNyitasZaras`, `MetroForgalomGyujtes`, `TescoForgalomGyujtes`, `WuniAfaBerogzites`, `MNBArfolyamLetoltes`, `KeszletKorzetSummazas`, `KeszletKorzetSumNullazo`, `KeszletKorzetSumRogzito`, `KeszletKftSummazas`, `KeszletKftSumRogzito`, `KeszletCegSummazas`, `KeszletCegSumNullazo`, `KeszletCegSumRogzito`, `ForgKorzetSummazas`, `ForgKorzetSumNullazo`

## Érintett adatbázis-táblák
`ARFOLYAM`, `CIMLETGYUJTO`, `DTABLA`, `FORGALOMGYUJTO`, `IDOSZAK`, `IRODAK`, `PENZTARKOZOTT`, `STORNOFEJ`, `STORNOTETEL`, `SUMBANKFORGALOM`, `TRBGYUJTO`, `WUNIGYUJTO`

**SQL-műveletek (minta):**
- `SELECT * FROM`
- `WHERE DATUM<=`
- `WHERE DATUM=`
- `INSERT INTO CIMLETGYUJTO (IRODASZAM,ERTEKTAR,CEGBETU,`
- `SELECT FEJ.*, TET.*`
- `FROM`
- `WHERE`
- `SELECT * FROM FORGALOMGYUJTO`
- `WHERE IRODASZAM=`
- `INSERT INTO FORGALOMGYUJTO (VALUTANEM,IRODASZAM,CEGBETU,`
- `UPDATE FORGALOMGYUJTO`
- `SELECT * FROM PENZTARKOZOTT`

## Felhasználói üzenetek (üzleti szabály-jelek)
_(nincs kinyerhető üzenet)_

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
