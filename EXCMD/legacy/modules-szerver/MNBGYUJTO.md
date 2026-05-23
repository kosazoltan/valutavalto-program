# Legacy modul (SZERVER): MNBGYUJTO

> Forrás (primer): `Anti/SZERVER/_extracted/SZERVER/ujdll/mnbgyujto/debug/unit2.pas` (50782 karakter) · library: `Anti/SZERVER/_extracted/SZERVER/ujdll/mnbgyujto/makedll/gyujto.dpr`
> Alrendszer: **SZERVER** — a tényleges Delphi-forrásból.
> Mély-elemzés: exportált API + tényleges .pas logika + SQL/DB + üzenetek + DFM.

## Exportált API (DLL-szerződés)
`adatlegyujtorutin`

## DFM form(ok) / képernyő
`TForm1`, `TMNBLEGYUJTO`

**Feliratok/gombok (Caption):** Form1 · INDIT · KILEP · 2020 szeptember 12 -23 · MESSPANEL

## Eljárások / függvények (.pas)
`AdatKiertekeles`, `FormActivate`, `GetZarok`, `ForgalomGyujtes`, `KorzetSumma`, `KorzetNullazo`, `KftSumma`, `KftNullazo`, `CegSumma`, `CegNullazo`, `EgyPenztarFeliras`, `KorzetFeliras`, `KFTFeliras`, `CegFeliras`, `IrodaBetolto`, `MNBParancs`, `IrodaTombNullazo`, `KilepoTimer`, `ForgalomNullazo`, `NyitoNullazo`, `ZaroNullazo`, `FBizonylatFeldolgozo`, `UBizonylatFeldolgozo`, `Nulele`, `DnemScan`, `RealToStr`, `Kerekito`, `KorzetScan`, `DateCtrl`, `TMNBLEGYUJTO.FormActivate`

## Érintett adatbázis-táblák
`IDOSZAK`, `IRODAK`, `MNB`

**SQL-műveletek (minta):**
- `DELETE FROM MNB`
- `SELECT FEJ.*, TET.*`
- `FROM`
- `WHERE`
- `INSERT INTO MNB (ERTEKTAR,IRODASZAM,VALUTANEM,NYITO,`
- `SELECT * FROM IRODAK`
- `SELECT * FROM IDOSZAK`
- `SELECT * FROM`
- `WHERE DATUM<`
- `WHERE DATUM=`
- `WHERE DATUM<=`

## Felhasználói üzenetek (üzleti szabály-jelek)
- HIBÁS IDŐSZAK MEGADÁSA

## Megfeleltetés a jelenlegi programmal
_(TBD — a jelenlegi Java/React/Electron értéktár-funkciók ellen verifikálandó; gap-jelölt, ha a fenti logika/üzenet hiányzik.)_
